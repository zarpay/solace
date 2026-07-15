# frozen_string_literal: true

module Solace
  module Utils
    # Utility for managing address lookup tables for composers
    #
    # This utility holds the lookup tables made available to a transaction composer and
    # encapsulates the v0 loading rules: which compiled accounts may be loaded through a
    # table instead of occupying a static account slot, and which table references the
    # final message must carry. Concerns like deduplication across tables and preserving
    # the runtime's loaded-address order are handled by this utility.
    #
    # @example Usage
    #   # Create a new lookup table context
    #   lookup_tables = Solace::Utils::LookupTableContext.new
    #
    #   # Register a table (address + its full on-chain address list)
    #   lookup_tables.add_table(account: table_address, addresses: addresses)
    #
    #   # Split the loadable accounts of a compiled account context
    #   writable, readonly = lookup_tables.select_loaded_accounts(account_context, program_ids)
    #
    #   # Build the table references for a v0 message
    #   lookup_tables.address_lookup_tables_for(writable, readonly)
    #
    # @see Solace::TransactionComposer
    # @see Solace::Utils::AccountContext
    # @since 0.1.8
    class LookupTableContext
      # @!attribute tables
      #   The registered lookup tables
      #
      # @return [Array<Hash>] The tables as { account:, addresses: } hashes
      attr_reader :tables

      # Initialize the lookup table context
      def initialize
        @tables = []
      end

      # Register a lookup table
      #
      # @param account [#to_s, PublicKey] The lookup table's on-chain address
      # @param addresses [Array<#to_s>] The full, ordered list of addresses stored in the table
      # @return [LookupTableContext] Self for chaining
      def add_table(account:, addresses:)
        tables << { account: account.to_s, addresses: addresses.map(&:to_s) }
        self
      end

      # Predicate to check if any lookup tables are registered
      #
      # @return [Boolean] Whether the context has no tables
      def empty?
        tables.empty?
      end

      # Select the compiled accounts to load through the lookup tables
      #
      # An account is loadable when it is referenced by the compiled account context,
      # can never sign (loaded accounts must not be signers or the fee payer), and is
      # not one of the given program ids (top-level program ids must stay static —
      # runtime rules). First-wins over tables and positions, so iteration order
      # matches the runtime's loaded-address order (per table, ascending position)
      # within each segment.
      #
      # @param account_context [AccountContext] The compiled account context
      # @param program_ids [Array<String>] Program ids referenced by the instructions
      # @return [Array(Hash, Hash)] The writable and readonly segments as
      #   pubkey => { table_index:, address_index: } hashes
      def select_loaded_accounts(account_context, program_ids)
        chosen = choose_accounts(account_context, program_ids)

        chosen
          .partition { |pubkey, _ref| account_context.writable?(pubkey) }
          .map(&:to_h)
      end

      # Build the lookup table references carried by a v0 message
      #
      # Tables that contribute no loaded accounts are omitted.
      #
      # @param writable [Hash{String => Hash}] Loaded writable pubkey => { table_index:, address_index: }
      # @param readonly [Hash{String => Hash}] Loaded readonly pubkey => { table_index:, address_index: }
      # @return [Array<Solace::AddressLookupTable>] The lookup table references
      def address_lookup_tables_for(writable, readonly)
        tables.each_with_index.filter_map do |table, table_index|
          writable_indexes = indexes_for(writable, table_index)
          readonly_indexes = indexes_for(readonly, table_index)
          next if writable_indexes.empty? && readonly_indexes.empty?

          Solace::AddressLookupTable.new.tap do |alt|
            alt.account          = table[:account]
            alt.writable_indexes = writable_indexes
            alt.readonly_indexes = readonly_indexes
          end
        end
      end

      private

      # Choose the accounts to load, keyed by pubkey with their table references
      #
      # @param account_context [AccountContext] The compiled account context
      # @param program_ids [Array<String>] Program ids referenced by the instructions
      # @return [Hash{String => Hash}] pubkey => { table_index:, address_index: }
      def choose_accounts(account_context, program_ids)
        chosen = {}

        tables.each_with_index do |table, table_index|
          table[:addresses].each_with_index do |pubkey, address_index|
            next if chosen.key?(pubkey) || !loadable?(pubkey, account_context, program_ids)

            chosen[pubkey] = { table_index: table_index, address_index: address_index }
          end
        end

        chosen
      end

      # Predicate to check if an account may be loaded through a lookup table
      #
      # @param pubkey [String] The pubkey of the account
      # @param account_context [AccountContext] The compiled account context
      # @param program_ids [Array<String>] Program ids referenced by the instructions
      # @return [Boolean] Whether the account may be loaded
      def loadable?(pubkey, account_context, program_ids)
        account_context.pubkey_account_map.key?(pubkey) &&
          !account_context.signer?(pubkey) &&
          !account_context.fee_payer?(pubkey) &&
          !program_ids.include?(pubkey)
      end

      # Positions contributed by one lookup table for a segment of loaded accounts
      #
      # @param segment [Hash{String => Hash}] Loaded pubkey => { table_index:, address_index: }
      # @param table_index [Integer] The lookup table's position in {#tables}
      # @return [Array<Integer>] The address positions within the table
      def indexes_for(segment, table_index)
        segment.filter_map { |_pubkey, ref| ref[:address_index] if ref[:table_index] == table_index }
      end
    end
  end
end

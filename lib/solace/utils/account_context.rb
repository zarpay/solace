# frozen_string_literal: true

module Solace
  module Utils
    # Utility for managing account context for composers
    #
    # This utility is used to manage the accounts in a transaction composer and instructions composer. It
    # provides methods for managing the accounts and their permissions, as well as compiling the accounts
    # into the final format required by the instruction builders. Concerns like deduplication and ordering
    # are handled by this utility.
    #
    # @example Usage
    #   # Create a new account context
    #   context = Solace::Utils::AccountContext.new
    #
    #   # Add accounts
    #   context.add_writable_signer('pubkey1')
    #   context.add_readonly_nonsigner('pubkey2')
    #
    #   # Merge accounts from another context
    #   context = context.merge_from(other_context)
    #
    #   # Set fee payer
    #   context.set_fee_payer('pubkey3')
    #
    #   # Compile the accounts
    #   context.compile
    #
    # @see Solace::TransactionComposer
    # @see Solace::Composers::Base
    # @since 0.0.3
    class AccountContext
      # @!attribute  DEFAULT_ACCOUNT
      #   The default account data
      #
      # @return [Hash] The default account data with lowest level of permissions
      DEFAULT_ACCOUNT = {
        signer: false,
        writable: false,
        fee_payer: false
      }.freeze

      # @!attribute  header
      #   The header for the transaction
      #
      # @return [Array<Integer>] The header for the transaction
      attr_accessor :header

      # @!attribute  accounts
      #   The accounts in the transaction
      #
      # @return [Array<String>] The accounts
      attr_accessor :accounts

      # @!attribute  pubkey_account_map
      #   The map of accounts
      #
      # @return [Hash] The map of accounts
      attr_accessor :pubkey_account_map

      # Initialize the account context
      def initialize
        @header = []
        @accounts = []
        @pubkey_account_map = {}
      end

      # Set the fee payer account
      #
      # @param pubkey [Solace::Keypair, Solace::PublicKey, String] The pubkey of the fee payer account
      def set_fee_payer(pubkey)
        merge_account(pubkey, signer: true, writable: true, fee_payer: true)
      end

      # Add a signer account
      #
      # @param pubkey [Solace::Keypair, Solace::PublicKey, String] The pubkey of the signer account
      def add_writable_signer(pubkey)
        merge_account(pubkey, signer: true, writable: true)
      end

      # Add a writable account
      #
      # @param pubkey [Solace::Keypair, Solace::PublicKey, String] The pubkey of the writable account
      def add_writable_nonsigner(pubkey)
        merge_account(pubkey, signer: false, writable: true)
      end

      # Add a readonly signer account
      #
      # @param pubkey [Solace::Keypair, Solace::PublicKey, String] The pubkey of the readonly signer account
      def add_readonly_signer(pubkey)
        merge_account(pubkey, signer: true, writable: false)
      end

      # Add a readonly account
      #
      # @param pubkey [Solace::Keypair, Solace::PublicKey, String] The pubkey of the readonly account
      def add_readonly_nonsigner(pubkey)
        merge_account(pubkey, signer: false, writable: false)
      end

      # Predicate to check if an account is a fee payer
      #
      # @param pubkey [String] The pubkey of the account
      # @return [Boolean] Whether the account is a fee payer
      def fee_payer?(pubkey)
        @pubkey_account_map[pubkey].try { |acc| acc[:fee_payer] }
      end

      # Predicate to check if an account is a signer
      #
      # @param pubkey [String] The pubkey of the account
      # @return [Boolean] Whether the account is a signer
      def signer?(pubkey)
        @pubkey_account_map[pubkey].try { |acc| acc[:signer] }
      end

      # Predicate to check if an account is writable
      #
      # @param pubkey [String] The pubkey of the account
      # @return [Boolean] Whether the account is writable
      def writable?(pubkey)
        @pubkey_account_map[pubkey].try { |acc| acc[:writable] }
      end

      # Predicate to check if an account is a writable signer
      #
      # @param pubkey [String] The pubkey of the account
      # @return [Boolean] Whether the account is a writable signer
      def writable_signer?(pubkey)
        @pubkey_account_map[pubkey].try { |acc| acc[:signer] && acc[:writable] }
      end

      # Predicate to check if an account is writable and not a signer
      #
      # @param pubkey [String] The pubkey of the account
      # @return [Boolean] Whether the account is writable and not a signer
      def writable_nonsigner?(pubkey)
        @pubkey_account_map[pubkey].try { |acc| !acc[:signer] && acc[:writable] }
      end

      # Predicate to check if an account is a readonly signer
      #
      # @param pubkey [String] The pubkey of the account
      # @return [Boolean] Whether the account is a readonly signer
      def readonly_signer?(pubkey)
        @pubkey_account_map[pubkey].try { |acc| acc[:signer] && !acc[:writable] }
      end

      # Predicate to check if an account is readonly and not a signer
      #
      # @param pubkey [String] The pubkey of the account
      # @return [Boolean] Whether the account is readonly and not a signer
      def readonly_nonsigner?(pubkey)
        @pubkey_account_map[pubkey].try { |acc| !acc[:signer] && !acc[:writable] }
      end

      # Merge all accounts from another AccountContext into this one
      #
      # @param other_context [AccountContext] The other context to merge from
      def merge_from(other_context)
        other_context.pubkey_account_map.each do |pubkey, data|
          signer, writable, fee_payer = data.values_at(:signer, :writable, :fee_payer)
          merge_account(pubkey, signer: signer, writable: writable, fee_payer: fee_payer)
        end
      end

      # Compile accounts into final format
      #
      # Gets unique accounts and sorts them in the following order:
      #   - Signers first (Solana requirement)
      #   - Then writable accounts
      #   - Then readonly accounts
      #
      # @return [Hash] The compiled accounts and header
      def compile
        self.header = calculate_header
        self.accounts = order_accounts
        self
      end

      # Index of a pubkey in the accounts array
      #
      # @param pubkey_str [String] The public key of the account
      # @return [Integer] The index of the pubkey in the accounts array or -1 if not found
      def index_of(pubkey_str)
        indices[pubkey_str] || -1
      end

      # Get map of indicies for pubkeys in accounts array
      #
      # @return [Hash{String => Integer}] The indices of the pubkeys in the accounts array
      def indices
        accounts.each_with_index.to_h
      end

      private

      # Add or merge an account into the context
      #
      # @param pubkey [String, Solace::PublicKey, Solace::Keypair] The public key of the account
      # @param signer [Boolean] Whether the account is a signer
      # @param writable [Boolean] Whether the account is writable
      # @param [Boolean] fee_payer
      def merge_account(pubkey, signer:, writable:, fee_payer: false)
        pubkey_str = pubkey.is_a?(String) ? pubkey : pubkey.address

        @pubkey_account_map[pubkey_str] ||= DEFAULT_ACCOUNT.dup
        @pubkey_account_map[pubkey_str][:signer] ||= signer
        @pubkey_account_map[pubkey_str][:writable] ||= writable
        @pubkey_account_map[pubkey_str][:fee_payer] ||= fee_payer

        self
      end

      # Order accounts by signer, writable, readonly signer, readonly
      #
      # @return [Array<String>] The ordered accounts
      def order_accounts
        @pubkey_account_map.keys.sort_by do |pubkey|
          if fee_payer?(pubkey) then 0
          elsif writable_signer?(pubkey) then 1
          elsif readonly_signer?(pubkey) then 2
          elsif writable_nonsigner?(pubkey) then 3
          elsif readonly_nonsigner?(pubkey) then 4
          else
            raise ArgumentError, "Unknown account type for pubkey: #{pubkey}"
          end
        end
      end

      # Calculate the header for the transaction
      #
      # @note The header is an array of three integers:
      #   - The number of signers (writable + readonly)
      #   - The number of readonly signers
      #   - The number of readonly unsigned accounts
      #
      # @return [Array] The header for the transaction
      def calculate_header
        @pubkey_account_map.keys.each_with_object([0, 0, 0]) do |pubkey, acc|
          acc[0] += 1 if signer?(pubkey)

          if readonly_signer?(pubkey) then acc[1] += 1
          elsif readonly_nonsigner?(pubkey) then acc[2] += 1
          end
        end
      end
    end
  end
end

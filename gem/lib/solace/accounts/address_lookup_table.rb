# frozen_string_literal: true

module Solace
  # On-chain account models — the account state living at an address, as opposed
  # to the wire-level structures that reference it. Conventions for these types
  # (fetching, deserializing, deriving) are expected to grow here.
  module Accounts
    # Models an on-chain Address Lookup Table account: its address, the metadata
    # the program stores (authority, activation slots), and the full, ordered
    # list of addresses it holds.
    #
    # This is distinct from {Solace::AddressLookupTable}, which is the *reference*
    # a v0 message carries (a table account plus the writable/readonly index
    # positions into it). A composer decides which of this account's addresses
    # load — a v0 concern that needs the account context — and this object owns
    # the table-local part: turning the addresses it contributes into that
    # message reference.
    #
    # @example Register a table on a composer
    #   table = Solace::Accounts::AddressLookupTable.new(account: address, addresses: on_chain_addresses)
    #   table.reference(loaded_writable, loaded_readonly) # => Solace::AddressLookupTable or nil
    #
    # @example Read a table's on-chain state
    #   data  = Base64.decode64(connection.get_account_info(address)['data'][0])
    #   table = Solace::Accounts::AddressLookupTable.deserialize(StringIO.new(data))
    #   table.addresses # => the stored addresses
    #
    # @see Solace::AddressLookupTable
    # @see Solace::TransactionComposer
    # @since 0.1.7
    class AddressLookupTable
      # Byte offset at which the stored addresses begin — the program reserves a
      # fixed-size metadata region ahead of them regardless of its contents.
      META_SIZE = 56

      # @!attribute [r] account
      #   @return [String, nil] The lookup table's on-chain address
      attr_reader :account

      # @!attribute [r] addresses
      #   @return [Array<String>] The full, ordered list of addresses stored in the table
      attr_reader :addresses

      # @!attribute [r] authority
      #   @return [String, nil] The authority allowed to extend/close the table
      attr_reader :authority

      # @!attribute [r] deactivation_slot
      #   @return [Integer, nil] The slot the table was deactivated in (max while active)
      attr_reader :deactivation_slot

      # @!attribute [r] last_extended_slot
      #   @return [Integer, nil] The slot the table was last extended in
      attr_reader :last_extended_slot

      # Deserialize an on-chain lookup table account
      #
      # The BufferLayout is:
      #   - [State type (4 bytes, u32 LE)]
      #   - [Deactivation slot (8 bytes, u64 LE)]
      #   - [Last extended slot (8 bytes, u64 LE)]
      #   - [Last extended start index (1 byte)]
      #   - [Authority (Borsh Option<Pubkey>)]
      #   - [Padding, up to {META_SIZE}]
      #   - [Addresses (32 bytes each, to end of data)]
      #
      # @param io [IO, StringIO] The account data to read from
      # @return [AddressLookupTable] The parsed table
      def self.deserialize(io)
        Utils::Codecs.decode_le_u32(io) # state type (1 = lookup table); positional
        deactivation_slot  = Utils::Codecs.decode_le_u64(io)
        last_extended_slot = Utils::Codecs.decode_le_u64(io)

        Utils::Codecs.decode_u8(io) # last extended start index; positional
        authority = Utils::Codecs.decode_option_pubkey(io)

        io.seek(META_SIZE) # addresses begin after the fixed-size metadata region

        addresses = []
        addresses << Utils::Codecs.decode_pubkey(io) until io.eof?

        new(
          deactivation_slot:  deactivation_slot,
          last_extended_slot: last_extended_slot,
          authority:          authority,
          addresses:          addresses
        )
      end

      # Initialize a lookup table account
      #
      # @param account [#to_s, PublicKey, nil] The lookup table's on-chain address
      # @param addresses [Array<#to_s>, nil] The full, ordered address list; may be
      #   omitted (the composer then loads nothing through this table)
      # @param authority [String, nil] The table authority
      # @param deactivation_slot [Integer, nil] The deactivation slot
      # @param last_extended_slot [Integer, nil] The last extended slot
      def initialize(account: nil, addresses: nil, authority: nil, deactivation_slot: nil, last_extended_slot: nil)
        @account            = account&.to_s
        @addresses          = Array(addresses).map(&:to_s)
        @authority          = authority
        @deactivation_slot  = deactivation_slot
        @last_extended_slot = last_extended_slot
      end

      # Build the v0 message reference for the addresses this table contributes
      #
      # @param writable [Array<String>] Loaded writable pubkeys drawn from this table
      # @param readonly [Array<String>] Loaded readonly pubkeys drawn from this table
      # @return [Solace::AddressLookupTable, nil] The reference, or nil if it loads nothing
      def reference(writable, readonly)
        writable_indexes = positions_of(writable)
        readonly_indexes = positions_of(readonly)
        return if writable_indexes.empty? && readonly_indexes.empty?

        Solace::AddressLookupTable.new.tap do |reference|
          reference.account          = account
          reference.writable_indexes = writable_indexes
          reference.readonly_indexes = readonly_indexes
        end
      end

      private

      # Positions of the given pubkeys within this table's address list
      #
      # @param pubkeys [Array<String>] The pubkeys to locate
      # @return [Array<Integer>] Their positions in {#addresses}
      def positions_of(pubkeys)
        pubkeys.filter_map { |pubkey| addresses.index(pubkey) }
      end
    end
  end
end

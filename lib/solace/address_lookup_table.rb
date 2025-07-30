# encoding: ASCII-8BIT
# frozen_string_literal: true

module Solace
  # Represents a Solana Address Lookup Table account.
  #
  # This class models the internal structure of a deserialized address lookup table and provides
  # access to the account key, writable indexes, and readonly indexes.
  #
  # It includes serialization and deserialization logic for encoding and decoding the table
  # according to Solana’s buffer layout.
  #
  # ## Buffer Layout (in bytes):
  # - `[account (32 bytes)]`
  # - `[num_writable (compact-u16)]`
  # - `[writable indexes]`
  # - `[num_readonly (compact-u16)]`
  # - `[readonly indexes]`
  #
  # Includes `BinarySerializable`, enabling methods like `#to_binary`, `#to_io`, and `#to_bytes`.
  #
  # @example Deserialize from base64
  #   io = StringIO.new(base64)
  #   table = Solace::AddressLookupTable.deserialize(io)
  #
  # @example Serialize to base64
  #   table = Solace::AddressLookupTable.new
  #   table.account = pubkey
  #   table.writable_indexes = [1, 2]
  #   table.readonly_indexes = [3, 4]
  #   base64 = table.serialize
  #
  # @since 0.0.1
  class AddressLookupTable
    include Solace::Concerns::BinarySerializable

    # @!attribute [rw] account
    #   @return [String] The account key of the address lookup table
    attr_accessor :account

    # @!attribute [rw] writable_indexes
    #   @return [Array<Integer>] The writable indexes in the address lookup table
    attr_accessor :writable_indexes

    # @!attribute [rw] readonly_indexes
    #   @return [Array<Integer>] The readonly indexes in the address lookup table
    attr_accessor :readonly_indexes

    class << self
      # Deserializes an address lookup table from io stream
      #
      # @param io [IO, StringIO] The input to read bytes from.
      # @return [Solace::AddressLookupTable] Parsed address lookup table object
      def deserialize(io)
        Solace::Serializers::AddressLookupTableDeserializer.new(io).call
      end
    end

    # Serializes the address lookup table
    #
    # @return [String] The serialized address lookup table (base64)
    def serialize
      Solace::Serializers::AddressLookupTableSerializer.new(self).call
    end
  end
end

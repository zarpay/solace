# frozen_string_literal: true

# =============================
# Address Lookup Table Deserializer
# =============================
#
# Deserializes a Solana address lookup table from a binary format.
module Solace
  module Serializers
    class AddressLookupTableDeserializer < Solace::Serializers::BaseDeserializer
      # @!attribute record_class
      #   The class of the record being deserialized
      #
      # @return [Class] The class of the record
      self.record_class = Solace::AddressLookupTable

      # @!attribute steps
      #   An ordered list of methods to deserialize the address lookup table
      #
      # @return [Array] The steps to deserialize the address lookup table
      self.steps = %i[
        next_extract_account
        next_extract_writable_indexes
        next_extract_readonly_indexes
      ]

      # Extract the account key from the transaction
      #
      # The BufferLayout is:
      #   - [Account key (32 bytes)]
      #
      # @return [String] The account key
      def next_extract_account
        record.account = Codecs.bytes_to_base58 io.read(32).bytes
      end

      # Extract the writable indexes from the transaction
      #
      # The BufferLayout is:
      #   - [Number of writable indexes (compact u16)]
      #   - [Writable indexes (variable length u8)]
      #
      # @return [Array<Integer>] The writable indexes
      def next_extract_writable_indexes
        length, = Codecs.decode_compact_u16(io)
        record.writable_indexes = io.read(length).unpack('C*')
      end

      # Extract the readonly indexes from the transaction
      #
      # The BufferLayout is:
      #   - [Number of readonly indexes (compact u16)]
      #   - [Readonly indexes (variable length u8)]
      #
      # @return [Array<Integer>] The readonly indexes
      def next_extract_readonly_indexes
        length, = Codecs.decode_compact_u16(io)
        record.readonly_indexes = io.read(length).unpack('C*')
      end
    end
  end
end

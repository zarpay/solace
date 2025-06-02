# frozen_string_literal: true

module Solana
  module Serializers
    # =============================
    # Address Lookup Table Serializer
    # =============================
    #
    # Serializes a Solana address lookup table to a binary format.
    class AddressLookupTableSerializer < Serializers::Base
      # @!const SERIALIZATION_STEPS
      #   An ordered list of methods to serialize the address lookup table
      # 
      # @return [Array] The steps to serialize the address lookup table
      SERIALIZATION_STEPS = [
        :encode_account,
        :encode_writable_indexes,
        :encode_readonly_indexes
      ].freeze
      
      # Initialize a new serializer
      # 
      # @param address_lookup_table [Solana::AddressLookupTable] The address lookup table to serialize
      # @return [Solana::AddressLookupTableSerializer] The new serializer object
      def initialize(address_lookup_table)
        @alt = address_lookup_table
      end

      private

      attr_reader :alt

      # Encodes the account of the address lookup table
      # 
      # The BufferLayout is:
      #   - [Account key (32 bytes)]
      # 
      # @return [Array<Integer>] The bytes of the encoded account
      def encode_account
        Codecs.base58_to_bytes(alt.account)
      end

      # Encodes the writable indexes of the address lookup table
      # 
      # The BufferLayout is:
      #   - [Number of writable indexes (compact u16)]
      #   - [Writable indexes (variable length u8)]
      # 
      # @return [Array<Integer>] The bytes of the encoded writable indexes
      def encode_writable_indexes
        Codecs.encode_compact_u16(alt.writable_indexes.size).bytes + alt.writable_indexes
      end

      # Encodes the readonly indexes of the address lookup table
      # 
      # The BufferLayout is:
      #   - [Number of readonly indexes (compact u16)]
      #   - [Readonly indexes (variable length u8)]
      # 
      # @return [Array<Integer>] The bytes of the encoded readonly indexes
      def encode_readonly_indexes
        Codecs.encode_compact_u16(alt.readonly_indexes.size).bytes + alt.readonly_indexes
      end
    end
  end
end
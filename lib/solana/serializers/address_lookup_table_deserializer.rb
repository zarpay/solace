# frozen_string_literal: true

module Solana
  module Serializers
    # =============================
    # Address Lookup Table Serializer
    # =============================
    #
    # Serializes a Solana address lookup table to a binary format.
    class AddressLookupTableDeserializer < Serializers::Base
      include Solana::Utils

      # @!const DESERIALIZATION_STEPS
      #   An ordered list of methods to deserialize the address lookup table
      # 
      # @return [Array] The steps to deserialize the address lookup table
      DESERIALIZATION_STEPS = [
        :next_extract_account,
        :next_extract_writable_indexes,
        :next_extract_readonly_indexes
      ].freeze

      # Initialize a new serializer
      # 
      # @param io [IO or StringIO] The input to read bytes from.
      # @return [Solana::AddressLookupTableSerializer] The new serializer object
      def initialize(io)
        @io = io

        # Initialize address lookup table object
        @alt = Solana::AddressLookupTable.new
      end

      # Serializes the address lookup table
      # 
      # @return [String] The serialized address lookup table (base64)
      def call
        DESERIALIZATION_STEPS.each { send(_1) }

        alt
      end

      private

      attr_reader :alt, :io

      # Extract the account key from the transaction
      # 
      # The BufferLayout is:
      #   - [Account key (32 bytes)]
      # 
      # @return [String] The account key
      def next_extract_account
        alt.account = Codecs.bytes_to_base58 io.read(32).bytes
      end

      # Extract the writable indexes from the transaction
      # 
      # The BufferLayout is:
      #   - [Number of writable indexes (compact u16)]
      #   - [Writable indexes (variable length u8)]
      # 
      # @return [Array<Integer>] The writable indexes
      def next_extract_writable_indexes
        length, _ = Codecs.decode_compact_u16(io)
        alt.writable_indexes = io.read(length).unpack("C*")
      end

      # Extract the readonly indexes from the transaction
      # 
      # The BufferLayout is:
      #   - [Number of readonly indexes (compact u16)]
      #   - [Readonly indexes (variable length u8)]
      # 
      # @return [Array<Integer>] The readonly indexes
      def next_extract_readonly_indexes
        length, _ = Codecs.decode_compact_u16(io)
        alt.readonly_indexes = io.read(length).unpack("C*")
      end
    end
  end
end

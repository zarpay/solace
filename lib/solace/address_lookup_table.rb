# encoding: ASCII-8BIT
# frozen_string_literal: true

module Solace
  # !@class AddressLookupTable
  #
  # A class representing an address lookup table. Handles deserialization and serialization of address lookup tables.
  #
  # The BufferLayout is:
  #   - [Account key (32 bytes)]
  #   - [Number of writable indexes (compact u16)]
  #   - [Writable indexes (variable length)]
  #   - [Number of readonly indexes (compact u16)]
  #   - [Readonly indexes (variable length)]
  #
  # @return [Class]
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
        Solace::Serializers::AddressLookupTableDeserializer.call(io)
      end
    end

    # Serializes the address lookup table
    #
    # @return [String] The serialized address lookup table (base64)
    def serialize
      Solace::Serializers::AddressLookupTableSerializer.call(self)
    end
  end
end

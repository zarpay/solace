# frozen_string_literal: true

module Solace
  module Concerns
    # Adds binary serialization support to a class
    #
    # Transactions, Messages, Instructions, and AddressLookupTables are all binary serializable.
    # These classes use this concern to add binary serialization support.
    #
    # @see Solace::Transaction
    # @see Solace::Message
    # @see Solace::Instruction
    # @see Solace::AddressLookupTable
    # @since 0.0.1
    module BinarySerializable
      # Include the module
      #
      # @param base [Class] The base class to include the module into
      def self.included(base)
        base.extend ClassMethods
      end

      # Returns the binary decoded from the serialized string
      #
      # Expects the class to have a `serialize` method that returns a base64 string.
      #
      # @return [String] The binary decoded from the serialized string
      def to_binary
        Base64.decode64(serialize)
      end

      # Returns a StringIO stream of the binary data
      #
      # @return [IO] The StringIO stream of the binary data
      def to_io
        StringIO.new(to_binary)
      end

      # Returns the bytes of the binary data as an array of integers
      #
      # @return [Array] The bytes of the binary data as an array of integers
      def to_bytes
        to_binary.bytes
      end

      # Serializes the record to a binary format
      #
      # @return [String] The serialized record (binary)
      def serialize
        self.class::SERIALIZER.new(self).call
      rescue NameError => e
        raise "SERIALIZER must be defined: #{e.message}"
      end

      # Class methods for binary serializable
      module ClassMethods
        # Parse record from bytestream
        #
        # @param stream [IO, StringIO] The input to read bytes from.
        # @return [Solace::Instruction] Parsed instruction instance
        def deserialize(stream)
          self::DESERIALIZER.new(stream).call
        rescue NameError => e
          raise "DESERIALIZER must be defined: #{e.message}"
        end
      end
    end
  end
end

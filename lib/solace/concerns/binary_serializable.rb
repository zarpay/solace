# frozen_string_literal: true

module Solace
  module Concerns
    # !@module BinarySerializable
    #
    # @return [Module]
    module BinarySerializable
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
    end
  end
end

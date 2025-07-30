# frozen_string_literal: true

require 'base64'
require 'rbnacl'
require 'base58'
require 'stringio'

module Solace
  module Utils
    # Module for encoding and decoding data
    #
    # @since 0.0.1
    module Codecs
      # Creates a StringIO from a base64 string.
      #
      # @param base64 [String] The base64 string to decode
      # @return [StringIO] A StringIO object containing the decoded bytes
      def self.base64_to_bytestream(base64)
        StringIO.new(Base64.decode64(base64))
      end

      # Encodes a compact-u16 value in a compact form (shortvec)
      #
      # @param u16 [Integer] The compact-u16 value to encode
      # @return [String] The compactly encoded compact-u16 value
      def self.encode_compact_u16(u16)
        out = []

        loop do
          # In general, n >> 7 shifts the bits of n to the right by
          # 7 positions, effectively dividing n by 128 and discarding
          # the remainder (integer division). This is commonly used in
          # encoding schemes to process one "byte" (7 bits) at a time.
          if (u16 >> 7).zero?
            out << u16
            break
          end
          # The expression out << ((n & 0x7F) | 0x80) is used in variable-length
          # integer encoding, such as the compact-u16 encoding.
          #
          # n & 0x7F:
          #   - 0x7F is 127 in decimal, or 0111 1111 in binary.
          #   - n & 0x7F masks out all but the lowest 7 bits of n. This extracts the least significant 7 bits of n.
          #
          # (n & 0x7F) | 0x80:
          #   - 0x80 is 128 in decimal, or 1000 0000 in binary.
          #   - | (bitwise OR) sets the highest bit (the 8th bit) to 1.
          #   - This is a signal that there are more bytes to come in the encoding (i.e., the value hasn't been fully
          #     encoded yet).
          #
          # out << ...:
          #   - This appends the resulting byte to the out array.
          out << ((u16 & 0x7F) | 0x80)
          u16 >>= 7
        end

        out.pack('C*')
      end

      # Decodes a compact-u16 (ShortVec) value from an IO-like object.
      #
      # Reads bytes one at a time, accumulating the result until the MSB is 0.
      #
      # @param stream [IO, StringIO] The input to read bytes from.
      # @return [Integer, Integer] The decoded value and the number of bytes read.
      def self.decode_compact_u16(stream)
        value = 0
        shift = 0
        bytes_read = 0

        loop do
          byte = stream.read(1)
          raise EOFError, 'Unexpected end of input while decoding compact-u16' unless byte

          byte = byte.ord
          value |= (byte & 0x7F) << shift
          bytes_read += 1
          break if byte.nobits?(0x80)

          shift += 7
        end

        [value, bytes_read]
      end

      # Encodes a u64 value in little-endian format
      #
      # @param u64 [Integer] The u64 value to encode
      # @return [String] The little-endian encoded u64 value
      def self.encode_le_u64(u64)
        [u64].pack('Q<') # 64-bit little-endian
      end

      # Decodes a little-endian u64 value from a sequence of bytes
      #
      # @param stream [IO, StringIO] The input to read bytes from.
      # @return [Integer] The decoded u64 value
      def self.decode_le_u64(stream)
        stream.read(8).unpack1('Q<')
      end

      # Encodes a sequence of bytes in Base58 format
      #
      # @param binary [String] The bytes to encode
      # @return [String] The Base58 encoded string
      def self.binary_to_base58(binary)
        Base58.binary_to_base58(binary, :bitcoin)
      end

      # Decodes a Base58 string into a binary string
      #
      # @param string [String] The Base58 encoded string
      # @return [String] The decoded binary string
      def self.base58_to_binary(string)
        base58_to_bytes(string).pack('C*')
      end

      # Encodes a sequence of bytes in Base58 format
      #
      # @param bytes [String] The bytes to encode
      # @return [String] The Base58 encoded string
      def self.bytes_to_base58(bytes)
        binary_to_base58(bytes.pack('C*'))
      end

      # Decodes a Base58 string into a sequence of bytes
      #
      # @param string [String] The Base58 encoded string
      # @return [String] The decoded bytes
      def self.base58_to_bytes(string)
        Base58.base58_to_binary(string, :bitcoin).bytes
      end

      # Checks if a string is a valid Base58 string
      #
      # @param string [String] The string to check
      # @return [Boolean] True if the string is a valid Base58 string, false otherwise
      def self.valid_base58?(string)
        return false if string.nil? || string.empty?

        Base58.decode(string)
        true
      rescue StandardError => _e
        false
      end
    end
  end
end

# frozen_string_literal: true

require 'base64'
require 'rbnacl'
require 'base58'
require 'stringio'

module Solace
  module Utils
    # !@module Codecs
    #   A module for encoding and decoding data
    #
    # @return [Module]
    module Codecs
      # =============================
      # Helper: IO Stream
      # =============================
      #
      # Creates a StringIO from a base64 string.
      #
      # Args:
      #   base64 (String): The base64 string to decode
      #
      # Returns:
      #   StringIO: A StringIO object containing the decoded bytes
      #
      def self.base64_to_bytestream(base64)
        StringIO.new(Base64.decode64(base64))
      end

      # =============================
      # Helper: Compact-u16 Encoding (ShortVec)
      # =============================
      #
      # Encodes a u16 value in a compact form
      #
      # Args:
      #   u16 (Integer): The u16 value to encode
      #
      # Returns:
      #   String: The compactly encoded u16 value
      #
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

      # =============================
      # Helper: Compact-u16 Decoding (ShortVec)
      # =============================
      #
      # Decodes a compact-u16 (ShortVec) value from an IO-like object.
      # Reads bytes one at a time, accumulating the result until the MSB is 0.
      #
      # Args:
      #   stream (IO or StringIO): The input to read bytes from.
      #
      # Returns:
      #   [Integer, Integer]: The decoded value and the number of bytes read.
      #
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

      # =============================
      # Helper: Little-Endian u64 Encoding
      # =============================
      #
      # Encodes a u64 value in little-endian format
      #
      # Args:
      #   u64 (Integer): The u64 value to encode
      #
      # Returns:
      #   String: The little-endian encoded u64 value
      #
      def self.encode_le_u64(u64)
        [u64].pack('Q<') # 64-bit little-endian
      end

      # =============================
      # Helper: Little-Endian u64 Decoding
      # =============================
      #
      # Decodes a little-endian u64 value from a sequence of bytes
      #
      # Args:
      #   stream (IO or StringIO): The input to read bytes from.
      #
      # Returns:
      #   Integer: The decoded u64 value
      #
      def self.decode_le_u64(stream)
        stream.read(8).unpack1('Q<')
      end

      # =============================
      # Helper: Binary to Base58 Encoding
      # =============================
      #
      # Encodes a sequence of bytes in Base58 format
      #
      # Args:
      #   bytes (String): The bytes to encode
      #
      # Returns:
      #   String: The Base58 encoded string
      #
      def self.binary_to_base58(binary)
        Base58.binary_to_base58(binary, :bitcoin)
      end

      # =============================
      # Helper: Base58 Decoding
      # =============================
      #
      # Decodes a Base58 string into a binary string
      #
      # Args:
      #   string (String): The Base58 encoded string
      #
      # Returns:
      #   String: The decoded binary string
      #
      def self.base58_to_binary(string)
        base58_to_bytes(string).pack('C*')
      end

      # =============================
      # Helper: Base58 Encoding
      # =============================
      #
      # Encodes a sequence of bytes in Base58 format
      #
      # Args:
      #   bytes (String): The bytes to encode
      #
      # Returns:
      #   String: The Base58 encoded string
      #
      def self.bytes_to_base58(bytes)
        binary_to_base58(bytes.pack('C*'))
      end

      # =============================
      # Helper: Base58 Decoding
      # =============================
      #
      # Decodes a Base58 string into a sequence of bytes
      #
      # Args:
      #   string (String): The Base58 encoded string
      #
      # Returns:
      #   String: The decoded bytes
      #
      def self.base58_to_bytes(string)
        Base58.base58_to_binary(string, :bitcoin).bytes
      end

      # =============================
      # Helper: Base58 Validation
      # =============================
      #
      # Checks if a string is a valid Base58 string
      #
      # Args:
      #   string (String): The string to check
      #
      # Returns:
      #   Boolean: True if the string is a valid Base58 string, false otherwise
      #
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

# frozen_string_literal: true

require 'base64'
require 'rbnacl'
require 'base58'
require 'stringio'

module Solace
  # The Utils module contains utility classes and helper methods used throughout
  # the Solace gem.
  #
  # This module provides foundational utilities that support the core functionality
  # of the gem, including:
  # - {Solace::Utils::AccountContext} - Account management for transactions
  # - {Solace::Utils::Codecs} - Encoding and decoding utilities
  # - {Solace::Utils::Curve25519Dalek} - Cryptographic operations via FFI
  # - {Solace::Utils::PDA} - Program Derived Address generation
  # - {Solace::Utils::RPCClient} - Low-level RPC communication
  #
  # These utilities are primarily used internally by other parts of the gem, but
  # can also be used directly for advanced use cases.
  #
  # @see Solace::Connection
  # @see Solace::Keypair
  # @since 0.0.1
  module Utils
    # Module for encoding and decoding data.
    #
    # The helpers are grouped by category: base64/base58 string encodings,
    # fixed-width little-endian integers, the Solana compact-u16 (shortvec)
    # varint, length-prefixed byte/pubkey collections, and optionals.
    #
    # Serialization formats referenced below:
    # - "Borsh" — the Anchor serialization spec. Borsh encodes `bool` as a single
    #   0/1 byte, `Vec<T>`/`bytes` with a u32 little-endian length prefix, and
    #   `Option<T>` as a 1-byte discriminant (0 = None, 1 = Some) followed by the
    #   value. Methods that produce these layouts say so explicitly.
    # - "SmallVec" — a Solana/Anchor-program convention (e.g. Squads) that prefixes
    #   a collection with a u8 or u16 length instead of Borsh's u32. NOT Borsh.
    # - "compact-u16" / "shortvec" — Solana's own variable-length integer used in
    #   the transaction wire format. NOT Borsh.
    #
    # `extend self` exposes every method both as a module method
    # (Solace::Utils::Codecs.<method>) and as an instance method when the module is
    # included into a composed encoder/decoder.
    #
    # @since 0.0.1
    module Codecs
      extend self

      # --- Base64 -----------------------------------------------------------

      # Creates a StringIO from a base64 string.
      #
      # @param base64 [String] The base64 string to decode
      # @return [StringIO] A StringIO object containing the decoded bytes
      def base64_to_bytestream(base64)
        StringIO.new(Base64.decode64(base64))
      end

      # --- Base58 -----------------------------------------------------------

      # Encodes a binary string in Base58 format.
      #
      # @param binary [String] The bytes to encode
      # @return [String] The Base58 encoded string
      def binary_to_base58(binary)
        Base58.binary_to_base58(binary, :bitcoin)
      end

      # Decodes a Base58 string into a binary string
      #
      # @param string [String] The Base58 encoded string
      # @return [String] The decoded binary string
      def base58_to_binary(string)
        base58_to_bytes(string).pack('C*')
      end

      # Encodes a byte array in Base58 format
      #
      # @param bytes [Array<Integer>] The bytes to encode
      # @return [String] The Base58 encoded string
      def bytes_to_base58(bytes)
        binary_to_base58(bytes.pack('C*'))
      end

      # Decodes a Base58 string into a sequence of bytes
      #
      # @param string [String] The Base58 encoded string
      # @return [Array<Integer>] The decoded bytes
      def base58_to_bytes(string)
        Base58.base58_to_binary(string, :bitcoin).bytes
      end

      # Checks if a string is a valid Base58 string
      #
      # @param string [String] The string to check
      # @return [Boolean] True if the string is a valid Base58 string, false otherwise
      def valid_base58?(string)
        return false if string.nil? || string.empty?

        Base58.decode(string)
        true
      rescue StandardError => _e
        false
      end

      # --- Fixed-width little-endian integers -------------------------------

      # Encodes a u8 as a single byte.
      #
      # @param u8 [Integer] Value in range 0..255.
      # @return [Array<Integer>] A single-element byte array.
      def encode_u8(u8)
        [u8]
      end

      # Decodes a u8 from 1 byte.
      #
      # @param stream [IO, StringIO] The stream to read from.
      # @return [Integer] Value in range 0..255.
      def decode_u8(stream)
        stream.read(1).unpack1('C')
      end

      # Encodes a u16 as 2 little-endian bytes.
      #
      # @param u16 [Integer] Value in range 0..65535.
      # @return [String] 2-byte little-endian binary string.
      def encode_le_u16(u16)
        [u16].pack('S<')
      end

      # Decodes a u16 from 2 little-endian bytes.
      #
      # @param stream [IO, StringIO] The stream to read from.
      # @return [Integer] Value in range 0..65535.
      def decode_le_u16(stream)
        stream.read(2).unpack1('S<')
      end

      # Encodes a u32 as 4 little-endian bytes.
      #
      # @param u32 [Integer] Value in range 0..4294967295.
      # @return [String] 4-byte little-endian binary string.
      def encode_le_u32(u32)
        [u32].pack('L<')
      end

      # Decodes a u32 from 4 little-endian bytes.
      #
      # @param stream [IO, StringIO] The stream to read from.
      # @return [Integer] Value in range 0..4294967295.
      def decode_le_u32(stream)
        stream.read(4).unpack1('L<')
      end

      # Encodes a u64 value in little-endian format
      #
      # @param u64 [Integer] The u64 value to encode
      # @return [String] The little-endian encoded u64 value
      def encode_le_u64(u64)
        [u64].pack('Q<') # 64-bit little-endian
      end

      # Decodes a little-endian u64 value from a sequence of bytes
      #
      # @param stream [IO, StringIO] The input to read bytes from.
      # @return [Integer] The decoded u64 value
      def decode_le_u64(stream)
        stream.read(8).unpack1('Q<')
      end

      # Encodes a u128 as 16 little-endian bytes (two u64 words, low word first).
      #
      # @param u128 [Integer] Value in range 0..2**128-1.
      # @return [String] 16-byte little-endian binary string.
      def encode_le_u128(u128)
        [u128 & 0xFFFFFFFFFFFFFFFF, u128 >> 64].pack('Q<Q<')
      end

      # Decodes a u128 from 16 little-endian bytes (two u64 words, low word first).
      #
      # @param stream [IO, StringIO] The stream to read from.
      # @return [Integer] Value in range 0..2**128-1.
      def decode_le_u128(stream)
        lo, hi = stream.read(16).unpack('Q<Q<')
        lo + (hi << 64)
      end

      # Encodes an i64 as 8 little-endian bytes (two's complement).
      #
      # @param i64 [Integer] Value in range -2**63..2**63-1.
      # @return [String] 8-byte little-endian binary string.
      def encode_le_i64(i64)
        [i64].pack('q<')
      end

      # Decodes an i64 from 8 little-endian bytes (two's complement).
      #
      # @param stream [IO, StringIO] The stream to read from.
      # @return [Integer] Value in range -2**63..2**63-1.
      def decode_le_i64(stream)
        stream.read(8).unpack1('q<')
      end

      # --- Boolean ----------------------------------------------------------

      # Encodes a Borsh bool as a single byte: false → 0, true → 1.
      #
      # @param bool [Boolean] The value to encode.
      # @return [Array<Integer>] A single-element byte array.
      def encode_bool(bool)
        [bool ? 1 : 0]
      end

      # --- compact-u16 (Solana shortvec varint) -----------------------------

      # Encodes an integer as a compact-u16 (shortvec) varint. This is Solana's
      # transaction wire-format length prefix, NOT Borsh.
      #
      # @param u16 [Integer] The compact-u16 value to encode
      # @return [String] The compactly encoded compact-u16 value
      def encode_compact_u16(u16)
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

      # Decodes a compact-u16 (shortvec) value from an IO-like object.
      #
      # Reads bytes one at a time, accumulating the result until the MSB is 0.
      #
      # @param stream [IO, StringIO] The input to read bytes from.
      # @return [Integer, Integer] The decoded value and the number of bytes read.
      def decode_compact_u16(stream)
        value      = 0
        shift      = 0
        bytes_read = 0

        loop do
          byte = stream.read(1)
          raise EOFError, 'Unexpected end of input while decoding compact-u16' unless byte

          byte        = byte.ord
          value      |= (byte & 0x7F) << shift
          bytes_read += 1
          break if byte.nobits?(0x80)

          shift += 7
        end

        [value, bytes_read]
      end

      # --- Length-prefixed byte sequences -----------------------------------

      # Encodes a Borsh bytes field / Vec<u8>: u32 LE length prefix + raw bytes.
      #
      # @param bytes [Array<Integer>] The raw bytes.
      # @return [Array<Integer>]
      def encode_bytes(bytes)
        encode_le_u32(bytes.length).bytes + bytes
      end

      # Decodes a Borsh bytes / Vec<u8> field: u32 LE length prefix + raw bytes.
      #
      # @param stream [IO, StringIO] The stream to read from.
      # @return [String] The raw bytes as a binary string.
      def decode_bytes(stream)
        stream.read(decode_le_u32(stream))
      end

      # Encodes a SmallVec<u8, u8>: u8 length prefix + raw bytes. SmallVec is a
      # Solana/Anchor-program convention, NOT Borsh (which would use a u32 prefix).
      #
      # @param bytes [Array<Integer>] The raw bytes (max 255).
      # @return [Array<Integer>]
      def encode_smallvec_u8_bytes(bytes)
        [bytes.length] + bytes
      end

      # Encodes a SmallVec<u16, u8>: u16 LE length prefix + raw bytes. SmallVec is a
      # Solana/Anchor-program convention, NOT Borsh (which would use a u32 prefix).
      #
      # @param bytes [Array<Integer>] The raw bytes (max 65535).
      # @return [Array<Integer>]
      def encode_smallvec_u16_bytes(bytes)
        encode_le_u16(bytes.length).bytes + bytes
      end

      # --- Public keys ------------------------------------------------------

      # Encodes a public key as 32 raw bytes (a Solana primitive, not a Borsh
      # type). Accepts any representation that resolves to a base58 string via
      # #to_s (String, Keypair, PublicKey).
      #
      # @param pubkey [#to_s] The public key in any representation.
      # @return [Array<Integer>] 32 bytes.
      def encode_pubkey(pubkey)
        base58_to_bytes(pubkey.to_s)
      end

      # Decodes a public key from 32 bytes.
      #
      # @param stream [IO, StringIO] The stream to read from.
      # @return [String] Base58 public key.
      def decode_pubkey(stream)
        bytes_to_base58(stream.read(32).bytes)
      end

      # Encodes a Borsh Vec<publicKey>: u32 LE count prefix followed by each
      # 32-byte pubkey.
      #
      # @param pubkeys [Array<#to_s>] The public keys in any representation.
      # @return [Array<Integer>]
      def encode_vec_pubkeys(pubkeys)
        encode_le_u32(pubkeys.length).bytes +
          pubkeys.flat_map { |pubkey| encode_pubkey(pubkey) }
      end

      # Decodes a Borsh Vec<publicKey>: u32 LE count prefix followed by each
      # 32-byte pubkey.
      #
      # @param stream [IO, StringIO] The stream to read from.
      # @return [Array<String>] Base58 public keys.
      def decode_vec_pubkeys(stream)
        Array.new(decode_le_u32(stream)) { decode_pubkey(stream) }
      end

      # Encodes a SmallVec<u8, Pubkey>: u8 count prefix followed by each 32-byte
      # pubkey. SmallVec is a Solana convention (NOT Borsh); used by the
      # transaction message header's account_keys (distinct from
      # encode_vec_pubkeys, which uses Borsh's u32 count).
      #
      # @param pubkeys [Array<#to_s>] The public keys in any representation (max 255).
      # @return [Array<Integer>]
      def encode_smallvec_u8_pubkeys(pubkeys)
        [pubkeys.length] + pubkeys.flat_map { |pubkey| encode_pubkey(pubkey) }
      end

      # --- Optionals (Borsh Option<T>) --------------------------------------

      # Encodes a Borsh Option<publicKey>: None → [0], Some(key) → [1] + 32 bytes.
      #
      # @param pubkey [#to_s, nil] Base58 public key or nil.
      # @return [Array<Integer>]
      def encode_option_pubkey(pubkey)
        return [0] if pubkey.nil?

        [1] + encode_pubkey(pubkey)
      end

      # Decodes a Borsh Option<publicKey>: None → nil, Some(key) → base58 pubkey.
      #
      # @param stream [IO, StringIO] The stream to read from.
      # @return [String, nil] Base58 public key or nil.
      def decode_option_pubkey(stream)
        return nil if decode_u8(stream).zero?

        decode_pubkey(stream)
      end

      # Encodes a Borsh Option<i64>: None → [0], Some(i64) → [1] + 8 LE bytes.
      #
      # @param i64 [Integer, nil]
      # @return [Array<Integer>]
      def encode_option_i64(i64)
        return [0] if i64.nil?

        [1] + encode_le_i64(i64).bytes
      end

      # Decodes a Borsh Option<i64>: None → nil, Some(i64) → integer.
      #
      # @param stream [IO, StringIO] The stream to read from.
      # @return [Integer, nil]
      def decode_option_i64(stream)
        return nil if decode_u8(stream).zero?

        decode_le_i64(stream)
      end

      # Encodes a Borsh Option<String>:
      # None → [0], Some(str) → [1] + u32 LE length + UTF-8 bytes.
      #
      # @param str [String, nil]
      # @return [Array<Integer>]
      def encode_option_string(str)
        return [0] if str.nil?

        bytes = str.encode('UTF-8').bytes
        [1] + encode_le_u32(bytes.length).bytes + bytes
      end
    end
  end
end

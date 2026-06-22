# encoding: ASCII-8BIT
# frozen_string_literal: true

require 'test_helper'

describe Solace::Utils::Codecs do
  describe '#base64_to_bytestream' do
    it 'converts base64 string to bytestream' do
      stream = Solace::Utils::Codecs.base64_to_bytestream(
        "aXQgd29ya3M=\n" # base64 encoded "it works"
      )
      assert_equal 'it works', stream.read
    end
  end

  describe '#encode_compact_u16' do
    # Expected compact u16 values
    let(:valid_compact_u16_values) do
      {
        0 => "\x00".b,
        1 => "\x01".b,
        5 => "\x05".b,
        16 => "\x10".b,
        31 => "\x1f".b,
        63 => "\x3f".b,
        127 => "\x7f".b
      }
    end

    it 'encodes compact u16 values' do
      valid_compact_u16_values.each do |n, bytes|
        assert_equal(
          bytes,
          Solace::Utils::Codecs.encode_compact_u16(n),
          "Failed for n = #{n}, expected #{bytes} but got #{Solace::Utils::Codecs.encode_compact_u16(n).inspect}"
        )
      end
    end

    it 'decodes compact u16 values' do
      valid_compact_u16_values.each do |n, bytes|
        assert_equal(
          [n, bytes.length],
          Solace::Utils::Codecs.decode_compact_u16(StringIO.new(bytes)),
          "Failed for n = #{n}, expected #{bytes} but got #{Solace::Utils::Codecs.decode_compact_u16(StringIO.new(bytes)).inspect}"
        )
      end
    end
  end

  describe '#encode_le_u64' do
    # Expected little-endian U64 values
    let(:valid_le_u64_values) do
      {
        0 => "\x00\x00\x00\x00\x00\x00\x00\x00".b,
        1 => "\x01\x00\x00\x00\x00\x00\x00\x00".b,
        42 => "\x2a\x00\x00\x00\x00\x00\x00\x00".b,
        255 => "\xff\x00\x00\x00\x00\x00\x00\x00".b,
        256 => "\x00\x01\x00\x00\x00\x00\x00\x00".b,
        65_535 => "\xff\xff\x00\x00\x00\x00\x00\x00".b,
        4_294_967_295 => "\xff\xff\xff\xff\x00\x00\x00\x00".b,
        2**40 => "\x00\x00\x00\x00\x00\x01\x00\x00".b,
        2**63 => "\x00\x00\x00\x00\x00\x00\x00\x80".b
      }
    end

    it 'encodes little-endian u64 values' do
      valid_le_u64_values.each do |n, bytes|
        assert_equal(
          bytes,
          Solace::Utils::Codecs.encode_le_u64(n),
          "Failed for n = #{n}, expected #{bytes} but got #{Solace::Utils::Codecs.encode_le_u64(n).inspect}"
        )
      end
    end

    it 'decodes little-endian u64 values' do
      valid_le_u64_values.each do |n, bytes|
        assert_equal(
          n,
          Solace::Utils::Codecs.decode_le_u64(StringIO.new(bytes)),
          "Failed for n = #{n}, expected #{bytes} but got #{Solace::Utils::Codecs.decode_le_u64(StringIO.new(bytes)).inspect}"
        )
      end
    end
  end

  describe '#base58_to_bytes' do
    # Expected base58 values
    let(:valid_base58_mappings) do
      {
        '4k8k5d' => [146, 117, 191, 192],
        '11111111111111111111111111111111' => [0] * 32,
        'JxF12TrwUP45BMd' => [72, 101, 108, 108, 111, 32, 87, 111, 114, 108, 100],
        '2VFAhjXBhMuEbmcTtjYXAZX4oVPhr3im7yb8RmaBofU6' => [22, 23, 247, 244, 154, 76, 30, 91, 94, 94, 164, 29, 134, 66,
                                                           178, 4, 193, 195, 140, 79, 197, 35, 89, 202, 7, 85, 64, 99, 10, 23, 242, 235]
      }
    end

    it 'encodes base58 values' do
      valid_base58_mappings.each do |base58, bytes|
        assert_equal(
          base58,
          Solace::Utils::Codecs.bytes_to_base58(bytes),
          "Failed for base58 = #{base58}, expected #{bytes} but got #{Solace::Utils::Codecs.bytes_to_base58(bytes).inspect}"
        )
      end
    end

    it 'decodes base58 values' do
      valid_base58_mappings.each do |base58, bytes|
        assert_equal(
          bytes,
          Solace::Utils::Codecs.base58_to_bytes(base58),
          "Failed for base58 = #{base58}, expected #{bytes} but got #{Solace::Utils::Codecs.base58_to_bytes(base58).inspect}"
        )
      end
    end
  end

  # --- Borsh / Solana scalar and collection helpers ---------------------

  describe '#encode_u8 / #decode_u8' do
    let(:values) { { 0 => [0], 1 => [1], 42 => [42], 255 => [255] } }

    it 'round-trips u8 values' do
      values.each do |n, bytes|
        assert_equal bytes, Solace::Utils::Codecs.encode_u8(n)
        assert_equal n, Solace::Utils::Codecs.decode_u8(StringIO.new(bytes.pack('C*')))
      end
    end
  end

  describe '#encode_le_u16 / #decode_le_u16' do
    let(:values) do
      {
        0 => "\x00\x00".b,
        1 => "\x01\x00".b,
        256 => "\x00\x01".b,
        65_535 => "\xff\xff".b
      }
    end

    it 'round-trips little-endian u16 values' do
      values.each do |n, bytes|
        assert_equal bytes, Solace::Utils::Codecs.encode_le_u16(n)
        assert_equal n, Solace::Utils::Codecs.decode_le_u16(StringIO.new(bytes))
      end
    end
  end

  describe '#encode_le_u32 / #decode_le_u32' do
    let(:values) do
      {
        0 => "\x00\x00\x00\x00".b,
        1 => "\x01\x00\x00\x00".b,
        65_536 => "\x00\x00\x01\x00".b,
        4_294_967_295 => "\xff\xff\xff\xff".b
      }
    end

    it 'round-trips little-endian u32 values' do
      values.each do |n, bytes|
        assert_equal bytes, Solace::Utils::Codecs.encode_le_u32(n)
        assert_equal n, Solace::Utils::Codecs.decode_le_u32(StringIO.new(bytes))
      end
    end
  end

  describe '#encode_le_i64 / #decode_le_i64' do
    let(:values) do
      {
        0 => "\x00\x00\x00\x00\x00\x00\x00\x00".b,
        1 => "\x01\x00\x00\x00\x00\x00\x00\x00".b,
        -1 => "\xff\xff\xff\xff\xff\xff\xff\xff".b,
        -2 => "\xfe\xff\xff\xff\xff\xff\xff\xff".b,
        (2**63) - 1 => "\xff\xff\xff\xff\xff\xff\xff\x7f".b,
        -(2**63) => "\x00\x00\x00\x00\x00\x00\x00\x80".b
      }
    end

    it 'round-trips little-endian i64 values' do
      values.each do |n, bytes|
        assert_equal bytes, Solace::Utils::Codecs.encode_le_i64(n)
        assert_equal n, Solace::Utils::Codecs.decode_le_i64(StringIO.new(bytes))
      end
    end
  end

  describe '#encode_le_u128 / #decode_le_u128' do
    let(:values) do
      {
        0 => ([0] * 16).pack('C*'),
        1 => ([1] + ([0] * 15)).pack('C*'),
        2**64 => (([0] * 8) + [1] + ([0] * 7)).pack('C*'),
        (2**128) - 1 => ([255] * 16).pack('C*')
      }
    end

    it 'round-trips little-endian u128 values' do
      values.each do |n, bytes|
        assert_equal bytes, Solace::Utils::Codecs.encode_le_u128(n)
        assert_equal n, Solace::Utils::Codecs.decode_le_u128(StringIO.new(bytes))
      end
    end
  end

  describe '#encode_bool' do
    it 'encodes true and false' do
      assert_equal [1], Solace::Utils::Codecs.encode_bool(true)
      assert_equal [0], Solace::Utils::Codecs.encode_bool(false)
    end
  end

  describe '#encode_bytes / #decode_bytes' do
    it 'round-trips a Borsh Vec<u8> with a u32 length prefix' do
      bytes   = [1, 2, 3, 255]
      encoded = Solace::Utils::Codecs.encode_bytes(bytes)
      assert_equal [4, 0, 0, 0] + bytes, encoded
      assert_equal bytes.pack('C*'), Solace::Utils::Codecs.decode_bytes(StringIO.new(encoded.pack('C*')))
    end

    it 'round-trips an empty byte vector' do
      encoded = Solace::Utils::Codecs.encode_bytes([])
      assert_equal [0, 0, 0, 0], encoded
      assert_equal '', Solace::Utils::Codecs.decode_bytes(StringIO.new(encoded.pack('C*')))
    end
  end

  describe '#encode_smallvec_u8_bytes' do
    it 'prefixes raw bytes with a u8 count' do
      assert_equal [3, 10, 20, 30], Solace::Utils::Codecs.encode_smallvec_u8_bytes([10, 20, 30])
      assert_equal [0], Solace::Utils::Codecs.encode_smallvec_u8_bytes([])
    end
  end

  describe '#encode_smallvec_u16_bytes' do
    it 'prefixes raw bytes with a u16 LE count' do
      assert_equal [3, 0, 10, 20, 30], Solace::Utils::Codecs.encode_smallvec_u16_bytes([10, 20, 30])
      assert_equal [0, 0], Solace::Utils::Codecs.encode_smallvec_u16_bytes([])
    end
  end

  describe '#encode_pubkey / #decode_pubkey' do
    let(:pubkey) { '2VFAhjXBhMuEbmcTtjYXAZX4oVPhr3im7yb8RmaBofU6' }

    it 'round-trips a 32-byte public key' do
      encoded = Solace::Utils::Codecs.encode_pubkey(pubkey)
      assert_equal 32, encoded.length
      assert_equal pubkey, Solace::Utils::Codecs.decode_pubkey(StringIO.new(encoded.pack('C*')))
    end
  end

  describe '#encode_vec_pubkeys / #decode_vec_pubkeys' do
    let(:pubkeys) do
      %w[2VFAhjXBhMuEbmcTtjYXAZX4oVPhr3im7yb8RmaBofU6 11111111111111111111111111111111]
    end

    it 'round-trips a Vec<publicKey> with a u32 count' do
      encoded = Solace::Utils::Codecs.encode_vec_pubkeys(pubkeys)
      assert_equal [2, 0, 0, 0], encoded.first(4)
      assert_equal 4 + (32 * 2), encoded.length
      assert_equal pubkeys, Solace::Utils::Codecs.decode_vec_pubkeys(StringIO.new(encoded.pack('C*')))
    end

    it 'round-trips an empty Vec<publicKey>' do
      encoded = Solace::Utils::Codecs.encode_vec_pubkeys([])
      assert_equal [0, 0, 0, 0], encoded
      assert_equal [], Solace::Utils::Codecs.decode_vec_pubkeys(StringIO.new(encoded.pack('C*')))
    end
  end

  describe '#encode_smallvec_u8_pubkeys' do
    let(:pubkeys) do
      %w[2VFAhjXBhMuEbmcTtjYXAZX4oVPhr3im7yb8RmaBofU6 11111111111111111111111111111111]
    end

    it 'prefixes pubkeys with a u8 count' do
      encoded = Solace::Utils::Codecs.encode_smallvec_u8_pubkeys(pubkeys)
      assert_equal 2, encoded.first
      assert_equal 1 + (32 * 2), encoded.length
    end
  end

  describe '#encode_option_pubkey / #decode_option_pubkey' do
    let(:pubkey) { '2VFAhjXBhMuEbmcTtjYXAZX4oVPhr3im7yb8RmaBofU6' }

    it 'encodes and decodes Some(pubkey)' do
      encoded = Solace::Utils::Codecs.encode_option_pubkey(pubkey)
      assert_equal 1, encoded.first
      assert_equal 33, encoded.length
      assert_equal pubkey, Solace::Utils::Codecs.decode_option_pubkey(StringIO.new(encoded.pack('C*')))
    end

    it 'encodes and decodes None' do
      encoded = Solace::Utils::Codecs.encode_option_pubkey(nil)
      assert_equal [0], encoded
      assert_nil Solace::Utils::Codecs.decode_option_pubkey(StringIO.new(encoded.pack('C*')))
    end
  end

  describe '#encode_option_i64 / #decode_option_i64' do
    it 'encodes and decodes Some(i64)' do
      encoded = Solace::Utils::Codecs.encode_option_i64(-42)
      assert_equal 1, encoded.first
      assert_equal 9, encoded.length
      assert_equal(-42, Solace::Utils::Codecs.decode_option_i64(StringIO.new(encoded.pack('C*'))))
    end

    it 'encodes and decodes None' do
      encoded = Solace::Utils::Codecs.encode_option_i64(nil)
      assert_equal [0], encoded
      assert_nil Solace::Utils::Codecs.decode_option_i64(StringIO.new(encoded.pack('C*')))
    end
  end

  describe '#encode_option_string' do
    it 'encodes Some(str) with a u32 length prefix' do
      assert_equal [1, 2, 0, 0, 0, 104, 105], Solace::Utils::Codecs.encode_option_string('hi')
    end

    it 'encodes None' do
      assert_equal [0], Solace::Utils::Codecs.encode_option_string(nil)
    end
  end
end

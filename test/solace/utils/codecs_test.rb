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
end

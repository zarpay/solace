# encoding: ASCII-8BIT

require 'test_helper'

class TestEncoder < Minitest::Test
  # Expected compact u16 values
  EXPECTED_COMPACT_U16_VALUES = {
    0 => "\x00".b,
    1 => "\x01".b,
    5 => "\x05".b,
    16 => "\x10".b,
    31 => "\x1f".b,
    63 => "\x3f".b,
    127 => "\x7f".b
  }

  def test_encode_compact_u16
    EXPECTED_COMPACT_U16_VALUES.each do |n, expected|
      assert_equal(
        expected, 
        Solana::Utils::Codecs.encode_compact_u16(n),
        "Failed for n = #{n}, expected #{expected} but got #{Solana::Utils::Codecs.encode_compact_u16(n).inspect}"
      )
    end
  end

  def test_decode_compact_u16
    EXPECTED_COMPACT_U16_VALUES.each do |n, expected|
      assert_equal(
        [n, expected.length],
        Solana::Utils::Codecs.decode_compact_u16(StringIO.new(expected)),
        "Failed for n = #{n}, expected #{expected} but got #{Solana::Utils::Codecs.decode_compact_u16(StringIO.new(expected)).inspect}"
      )
    end
  end

  # Expected little-endian U64 values
  EXPECTED_LE_U64_VALUES = {
    0 => "\x00\x00\x00\x00\x00\x00\x00\x00".b,
    1 => "\x01\x00\x00\x00\x00\x00\x00\x00".b,
    42 => "\x2a\x00\x00\x00\x00\x00\x00\x00".b,
    255 => "\xff\x00\x00\x00\x00\x00\x00\x00".b,
    256 => "\x00\x01\x00\x00\x00\x00\x00\x00".b,
    65535 => "\xff\xff\x00\x00\x00\x00\x00\x00".b,
    4294967295 => "\xff\xff\xff\xff\x00\x00\x00\x00".b,
    2**40 => "\x00\x00\x00\x00\x00\x01\x00\x00".b,
    2**63 => "\x00\x00\x00\x00\x00\x00\x00\x80".b
  }

  def test_encode_le_u64
    EXPECTED_LE_U64_VALUES.each do |n, expected|
      assert_equal(
        expected, 
        Solana::Utils::Codecs.encode_le_u64(n),
        "Failed for n = #{n}, expected #{expected} but got #{Solana::Utils::Codecs.encode_le_u64(n).inspect}"
      )
    end
  end
end

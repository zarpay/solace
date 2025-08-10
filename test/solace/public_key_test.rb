# frozen_string_literal: true

require 'test_helper'

describe Solace::PublicKey do
  before do
    # Example 32-byte key (all 1s)
    @bytes = Array.new(32, 1)
    @base58 = Solace::Utils::Codecs.bytes_to_base58(@bytes)
    @public_key = Solace::PublicKey.new(@bytes)
  end

  describe '#initialize' do
    it 'accepts 32-byte array' do
      assert_equal @bytes, @public_key.bytes
    end

    it 'raises on invalid length' do
      assert_raises(ArgumentError) { Solace::PublicKey.new([1, 2, 3]) }
    end
  end

  describe '#to_base58' do
    it 'returns base58 representation' do
      base58 = @public_key.to_base58
      assert_equal @base58, base58
    end
  end

  describe '#address' do
    it 'returns base58 representation' do
      assert_equal @base58, @public_key.address
    end
  end

  describe '#to_s' do
    it 'returns base58 representation' do
      assert_equal @base58, @public_key.to_s
    end
  end

  describe '#==' do
    it 'returns true for equal keys' do
      pk2 = Solace::PublicKey.new(@bytes.dup)
      refute_nil pk2
      assert_equal @public_key, pk2
    end

    it 'returns false for different keys' do
      pk3 = Solace::PublicKey.new(Array.new(32, 2))
      refute_equal @public_key, pk3
    end
  end

  describe '#to_s' do
    it 'returns base58 representation' do
      assert_equal @base58, @public_key.to_s
    end
  end

  describe '#to_bytes' do
    it 'returns copy o bytes' do
      bytes_copy = @public_key.to_bytes
      assert_equal @bytes, bytes_copy
      refute_same @public_key.bytes, bytes_copy
    end
  end

  describe '.from_address' do
    it 'returns public key instance from base58 address' do
      pk4 = Solace::PublicKey.from_address(@base58)

      assert_equal @public_key, pk4
    end

    it 'raises on invalid address' do
      assert_raises(ArgumentError) { Solace::PublicKey.from_address('invalid_address') }
    end
  end
end

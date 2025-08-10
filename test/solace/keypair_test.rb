# frozen_string_literal: true

require 'test_helper'
require 'base58'

describe Solace::Keypair do
  let(:klass) { Solace::Keypair }

  describe '.generate' do
    before do
      @keypair = klass.generate
    end

    it 'creates a valid keypair' do
      assert_kind_of klass, @keypair
    end
  end

  describe '.from_seed' do
    before do
      @seed = 'a' * 32
    end

    it 'creates a deterministic keypair' do
      keypair1 = klass.from_seed(@seed)
      keypair2 = klass.from_seed(@seed)

      assert_equal keypair1.address, keypair2.address
    end
  end

  describe '.from_secret_key' do
    before do
      @keypair = klass.generate
    end

    it 'creates a keypair from a secret' do
      secret = @keypair.keypair_bytes.pack('C*')
      keypair2 = klass.from_secret_key(secret)

      assert_equal @keypair.address, keypair2.address
    end
  end

  describe '#sign' do
    before do
      @keypair = klass.generate
    end

    it 'produces a valid signature' do
      signature = @keypair.sign('hello')

      assert_kind_of String, signature
      assert_equal 64, signature.bytesize
    end

    it 'signature changes with message' do
      sig1 = @keypair.sign('msg1')
      sig2 = @keypair.sign('msg2')

      assert sig1 != sig2
    end
  end

  describe '#public_key_bytes' do
    before do
      @keypair = klass.generate
    end

    it 'returns the public key bytes of the keypair' do
      assert_equal @keypair.public_key_bytes.length, @keypair.keypair_bytes[32..63]
    end
  end

  describe '#private_key_bytes' do
    before do
      @keypair = klass.generate
    end

    it 'returns the private key bytes of the keypair' do
      assert_equal @keypair.private_key_bytes.length, @keypair.keypair_bytes[0..31]
    end
  end

  describe '#to_base58' do
    before do
      @keypair = klass.generate
    end

    it 'returns the public key of the keypair as a Base58 string' do
      assert_equal @keypair.to_base58, @keypair.public_key.to_base58
    end
  end

  describe '#to_s' do
    before do
      @keypair = klass.generate
    end

    it 'returns the public key as a Base58 string' do
      assert_equal @keypair.to_base58, @keypair.to_s
    end
  end

  describe '#address' do
    before do
      @keypair = klass.generate
    end

    it 'returns the public key as a Base58 string' do
      assert_equal @keypair.to_base58, @keypair.address
    end
  end
end

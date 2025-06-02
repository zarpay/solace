# frozen_string_literal: true

require 'rbnacl'
require 'base58'

module Solana
  module Utils
    # =============================
    # Keypair
    # =============================
    #
    # Represents a Solana Ed25519 Keypair
    class Keypair
      attr_reader :keypair

      class << self
        # Generate a new random keypair
        #
        # @return [Keypair]
        def generate
          seed = RbNaCl::Random.random_bytes(RbNaCl::Signatures::Ed25519::SEEDBYTES)
          from_seed(seed)
        end

        # Create a keypair from a 32-byte seed
        #
        # @param seed [String] 32-byte array
        # @return [Keypair]
        def from_seed(seed)
          raise ArgumentError, 'Seed must be 32 bytes' unless seed.length == 32

          secret = RbNaCl::Signatures::Ed25519::SigningKey.new(seed)
          new(secret)
        end

        # Create a keypair from a 64-byte secret key
        # 
        # @param secret_key [String] 64-byte array
        # @return [Keypair]
        def from_secret_key(secret_key)
          raise ArgumentError, 'Secret key must be 64 bytes' unless secret_key.length == 64

          secret = RbNaCl::Signatures::Ed25519::SigningKey.new(secret_key[0,32].pack("C*"))
          new(secret)
        end
      end

      def initialize(signing_key)
        @keypair = signing_key
      end

      # Returns the public key as a Base58 string
      #
      # @return [String] Base58 encoded public key
      def public_key
        @keypair.verify_key.to_bytes
      end

      # Returns the public key as a Base58 string
      #
      # @return [String] Base58 encoded public key
      def address
        Solana::Utils::Codecs.bytes_to_base58(@keypair.keypair_bytes[32,32].bytes)
      end

      # Returns the secret key as a binary string (64 bytes: seed + public key)
      # 
      # @return [String] 64-byte array
      def secret_key
        @keypair.key_bytes
      end

      # Signs a message (string or binary)
      #
      # @param message [String]
      # @return [String] signature (binary)
      def sign(message)
        @keypair.sign(message)
      end
    end
  end
end

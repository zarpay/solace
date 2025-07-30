# frozen_string_literal: true

require 'rbnacl'
require 'base58'

module Solace
  # Class representing a Solana Ed25519 Keypair
  #
  # This class provides utility methods for encoding, decoding, signing, and validating keypairs.
  #
  # @example
  #   keypair = Solace::Keypair.generate
  #   keypair.address
  #   keypair.sign("<any-message>")
  #
  # @since 0.0.1
  class Keypair
    # !@const SECRET_LENGTH
    #   The length of a Solana secret key in bytes
    SECRET_LENGTH = 64

    # !@const SEED_LENGTH
    #   The length of a Solana seed in bytes (borrowed from RbNaCl = 32)
    SEED_LENGTH = RbNaCl::Signatures::Ed25519::SEEDBYTES

    # !@const SigningKey
    #   The RbNaCl signing key class
    SigningKey = RbNaCl::Signatures::Ed25519::SigningKey

    # !@attribute [r] keypair_bytes
    #   The keypair bytes
    attr_reader :keypair_bytes

    class << self
      # Generate a new random keypair
      #
      # @return [Keypair]
      def generate
        from_seed(RbNaCl::Random.random_bytes(SEED_LENGTH))
      end

      # Create a keypair from a 32-byte seed
      #
      # @param seed [String] 32-byte array
      # @return [Keypair]
      def from_seed(seed)
        raise ArgumentError, 'Seed must be 32 bytes' unless seed.length == SEED_LENGTH

        new(SigningKey.new(seed).keypair_bytes.bytes)
      end

      # Create a keypair from a 64-byte secret key
      #
      # @param secret_key [String] 64-byte array
      # @return [Keypair]
      def from_secret_key(secret_key)
        raise ArgumentError, 'Secret key must be 64 bytes' unless secret_key.length == SECRET_LENGTH

        new(SigningKey.new(secret_key[0..31]).keypair_bytes.bytes)
      end
    end

    # Initialize a new keypair
    #
    # @param keypair_bytes [Array<Integer>] The keypair bytes
    # @return [Keypair] The new keypair object
    def initialize(keypair_bytes)
      raise ArgumentError, 'Keypair must be 64 bytes' unless keypair_bytes.length == SECRET_LENGTH

      @keypair_bytes = keypair_bytes
    end

    # Returns the public key
    #
    # @return [PublicKey]
    def public_key
      @public_key ||= Solace::PublicKey.new(public_key_bytes)
    end

    # Returns the signing key
    #
    # @return [RbNaCl::Signatures::Ed25519::SigningKey]
    def signing_key
      @signing_key ||= SigningKey.new(private_key)
    end

    # Returns the public key bytes
    #
    # The public key bytes are the last 32 bytes of the keypair
    #
    # @return [String] 32 bytes
    def public_key_bytes
      keypair_bytes[32..63]
    end

    # Returns the private key
    #
    # The private key is the first 32 bytes of the keypair
    #
    # @return [String] 32 characters
    def private_key
      keypair_bytes[0..31].pack('C*')
    end

    # Returns the public key as a Base58 string
    #
    # @return [String] Base58 encoded public key
    def address
      public_key.to_base58
    end

    # Signs a message (string or binary)
    #
    # @param message [String, Binary]
    # @return [Binary] signature (binary)
    def sign(message)
      signing_key.sign(message)
    end
  end
end

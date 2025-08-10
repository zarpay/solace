# frozen_string_literal: true

require 'rbnacl'
require 'base58'

module Solace
  # Class representing a Solana Ed25519 Keypair
  #
  # This class provides utility methods for encoding, decoding, signing, and validating keypairs.
  #
  # @example
  #   # Generate a new keypair
  #   keypair = Solace::Keypair.generate
  #
  #   # Get the address of the pubkey
  #   keypair.address
  #
  #   # Sign a message using the keypair
  #   keypair.sign("<any-message>")
  #
  # @since 0.0.1
  class Keypair
    # The length of a Solana secret key in bytes.
    SECRET_LENGTH = 64

    # The length of a Solana seed in bytes.
    SEED_LENGTH = 32

    # The full keypair bytes array
    #
    # @return [Array<u8>] The 64 bytes of the keypair
    attr_reader :keypair_bytes

    class << self
      # Generate a new random keypair
      #
      # @example
      #   keypair = Solace::Keypair.generate
      #
      # @return [Keypair]
      def generate
        from_seed(RbNaCl::Random.random_bytes(SEED_LENGTH))
      end

      # Create a keypair from a 32-byte seed
      #
      # @example
      #   keypair = Solace::Keypair.from_seed(seed)
      #
      # @param seed [String] 32-byte array
      # @raise [ArgumentError] If the length of the seed isn't 32 bytes
      # @return [Keypair]
      def from_seed(seed)
        raise ArgumentError, 'Seed must be 32 bytes' unless seed.length == SEED_LENGTH

        new(RbNaCl::Signatures::Ed25519::SigningKey.new(seed).keypair_bytes.bytes)
      end

      # Create a keypair from a 64-byte secret key
      #
      # @example
      #   keypair = Solace::Keypair.from_secret_key(secret_key)
      #
      # @param secret_key [String] 64-byte array
      # @raise [ArgumentError] If the length of the secret_key isn't 64 bytes
      # @return [Keypair]
      def from_secret_key(secret_key)
        raise ArgumentError, 'Secret key must be 64 bytes' unless secret_key.length == SECRET_LENGTH

        new(RbNaCl::Signatures::Ed25519::SigningKey.new(secret_key[0..31]).keypair_bytes.bytes)
      end
    end

    # Initialize a new keypair
    #
    # @example
    #   keypair = Solace::Keypair.new(bytes)
    #
    # @param keypair_bytes [Array<Integer>] The keypair bytes
    # @raise [ArgumentError] If the length of the keypair_bytes isn't 64 bytes
    # @return [Keypair] The new keypair object
    def initialize(keypair_bytes)
      raise ArgumentError, 'Keypair must be 64 bytes' unless keypair_bytes.length == SECRET_LENGTH

      @keypair_bytes = keypair_bytes
    end

    # Returns the public key
    #
    # @example
    #   pubkey = keypair.public_key
    #
    # @return [PublicKey]
    def public_key
      @public_key ||= Solace::PublicKey.new(public_key_bytes)
    end

    # Returns the signing key
    #
    # @example
    #   signing_key = instance.signing_key
    #
    # @return [RbNaCl::Signatures::Ed25519::SigningKey]
    def signing_key
      @signing_key ||= RbNaCl::Signatures::Ed25519::SigningKey.new(private_key_bytes.pack('C*'))
    end

    # Returns the public key bytes
    #
    # The public key bytes are the last 32 bytes of the keypair
    #
    # @example
    #   public_key_bytes = instance.public_key_bytes
    #
    # @return [Array<u8>] 32 bytes
    def public_key_bytes
      keypair_bytes[32..63]
    end

    # Returns the private key
    #
    # The private key is the first 32 bytes of the keypair
    #
    # @example
    #   private_key_bytes = instance.private_key_bytes
    #
    # @return [Array<u8>] 32 characters
    def private_key_bytes
      keypair_bytes[0..31]
    end

    # Returns the public key address as a Base58 string
    #
    # @example
    #   pubkey_str = instance.to_base58
    #
    # @return [String] Base58 encoded public key
    def to_base58
      public_key.to_base58
    end

    # Returns the public key address as a Base58 string
    #
    # @example
    #   pubkey_str = instance.to_s
    #
    # @return [String] Base58 encoded public key
    # @since 0.0.8
    alias to_s to_base58

    # Returns the public key address as a Base58 string
    #
    # @example
    #   pubkey_str = instance.to_base58
    #
    # @return [String] Base58 encoded public key
    # @since 0.0.8
    alias address to_base58

    # Signs a message (string or binary)
    #
    # @example
    #   message = "An important message to be signed,"
    #   signature = instance.sign(message)
    #
    # @param message [String, Binary]
    # @return [String] signature (binary string)
    def sign(message)
      signing_key.sign(message)
    end
  end
end

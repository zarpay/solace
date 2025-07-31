# frozen_string_literal: true

module Solace
  # Class representing a Solana Ed25519 Public Key
  #
  # This class provides utility methods for encoding, decoding, and validating public keys.
  #
  # @example
  #   # Initialize a public key from a 32-byte array
  #   pubkey = Solace::PublicKey.new(public_key_bytes)
  #
  #   # Get the address representation of the public key
  #   pubkey.to_base58
  #   pubkey.address
  #
  # @since 0.0.1
  class PublicKey
    include Solace::Utils::PDA

    # The length of a Solana public key in bytes
    LENGTH = 32

    # The maximum seed value for a Program Derived Address
    MAX_BUMP_SEED = 255

    # The marker for a Program Derived Address
    PDA_MARKER = 'ProgramDerivedAddress'

    # The bytes of the public key
    #
    # @return [Array<u8>] The bytes of the public key
    attr_reader :bytes

    # Initialize with a 32-byte array or string
    #
    # @example
    #   pubkey = Solace::PubKey.new(bytes)
    #
    # @param bytes [String, Array<Integer>] 32-byte array or string
    # @raise [ArgumentError] If the public key bytes length isn't 32 long
    # @return [PublicKey]
    def initialize(bytes)
      raise ArgumentError, "Public key must be #{LENGTH} bytes" unless bytes.length == LENGTH

      @bytes = bytes.freeze
    end

    # Return the base58 representation of the public key
    #
    # @example
    #   pubkey_str = instance.to_base58
    #
    # @return [String]
    def to_base58
      Solace::Utils::Codecs.bytes_to_base58(@bytes)
    end

    # String representation (base58)
    #
    # @example
    #   pubkey_str = instance.to_s
    #
    # @return [String]
    def to_s
      to_base58
    end

    # Return the address of the public key
    #
    # @example
    #   pubkey_str = instance.address
    #
    # @return [String]
    def address
      to_base58
    end

    # Compare two public keys for equality
    #
    # @example
    #   pubkey1 == pubkey2
    #
    # @param other [PublicKey]
    # @return [Boolean]
    def ==(other)
      other.is_a?(Solace::PublicKey) && other.bytes == bytes
    end

    # Return the public key as a byte array
    #
    # @example
    #   pubkey_bytes = instance.to_bytes
    #
    # @return [Array<Integer>]
    def to_bytes
      @bytes.dup
    end
  end
end

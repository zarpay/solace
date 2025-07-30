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

    # !@const LENGTH
    #   The length of a Solana public key in bytes
    #
    # @return [Integer] The length of a public key
    LENGTH = 32

    # !@const MAX_BUMP_SEED
    #   The maximum seed value for a Program Derived Address
    #
    # @return [Integer] The maximum seed value
    MAX_BUMP_SEED = 255

    # !@const PDA_MARKER
    #   The marker for a Program Derived Address
    #
    # @return [String] The marker for a PDA
    PDA_MARKER = 'ProgramDerivedAddress'

    # !@attribute bytes
    #   @return [Array<Integer>] The bytes of the public key
    attr_reader :bytes

    # Initialize with a 32-byte array or string
    #
    # @param bytes [String, Array<Integer>] 32-byte array or string
    # @return [PublicKey]
    def initialize(bytes)
      raise ArgumentError, "Public key must be #{LENGTH} bytes" unless bytes.length == LENGTH

      @bytes = bytes.freeze
    end

    # Return the base58 representation of the public key
    #
    # @return [String]
    def to_base58
      Solace::Utils::Codecs.bytes_to_base58(@bytes)
    end

    # String representation (base58)
    #
    # @return [String]
    def to_s
      to_base58
    end

    # Return the address of the public key
    #
    # @return [String]
    def address
      to_base58
    end

    # Compare two public keys for equality
    #
    # @param other [PublicKey]
    # @return [Boolean]
    def ==(other)
      other.is_a?(Solace::PublicKey) && other.bytes == bytes
    end

    # Return the public key as a byte array
    #
    # @return [Array<Integer>]
    def to_bytes
      @bytes.dup
    end
  end
end

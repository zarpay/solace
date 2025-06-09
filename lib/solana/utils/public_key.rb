# frozen_string_literal: true

# =============================
# PublicKey
# =============================
#
# Represents a Solana Ed25519 Public Key
# Provides utility methods for encoding, decoding, and validation
class Solana::Utils::PublicKey
  # !@const LENGTH
  #   The length of a Solana public key in bytes
  # 
  # @return [Integer] The length of a public key
  LENGTH = 32

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

  # Create a PublicKey from a base58-encoded string
  # 
  # @param base58_str [String]
  # @return [PublicKey]
  def self.from_base58(base58_str)
    decoded = Solana::Utils::Codecs.base58_to_bytes(base58_str)
    new(decoded)
  end

  # Return the base58 representation of the public key
  # 
  # @return [String]
  def to_base58
    Solana::Utils::Codecs.bytes_to_base58(@bytes)
  end

  # String representation (base58)
  # 
  # @return [String]
  def to_s
    to_base58
  end

  # Compare two public keys for equality
  # 
  # @param other [PublicKey]
  # @return [Boolean]
  def ==(other)
    other.is_a?(Solana::Utils::PublicKey) && other.bytes == bytes
  end

  # Return the public key as a byte array
  # 
  # @return [Array<Integer>]
  def to_bytes
    @bytes.dup
  end
end

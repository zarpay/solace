# encoding: ASCII-8BIT

# =============================
# Transaction
# =============================
#
# Class representing a Solana transaction.
# 
# The BufferLayout is:
#   - [Signatures (variable length)]
#   - [Version (1 byte)] (if versioned)
#   - [Message header (3 bytes)]
#   - [Account keys (variable length)]
#   - [Recent blockhash (32 bytes)]
#   - [Instructions (variable length)]
#   - [Address lookup table (variable length)] (if versioned)
# 
class Solana::Transaction
  include Solana::Concerns::BinarySerializable

  # Signatures of the transaction (base58 encoded)
  attr_accessor :signatures

  # Message of the transaction
  attr_accessor :message

  class << self
    # Parse transaction from base64 string
    #
    # @param transaction_base64 [String] The base64 encoded transaction to deserialize
    # @return [Solana::Transaction] Parsed transaction object
    def deserialize(transaction_base64)
      Solana::Serializers::TransactionDeserializer.call(transaction_base64)
    end
  end

  # Initialize a new transaction
  # 
  # @return [Solana::Transaction] The new transaction object
  def initialize(
    signatures: [], 
    message: Solana::Message.new
  )
    # Set defaults
    @signatures = signatures
    @message = message
  end

  # Serializes the transaction to a binary format
  #
  # @return [String] The serialized transaction (binary)
  def serialize
    Solana::Serializers::TransactionSerializer.call(self)
  end

  # Signs the transaction
  #
  # Updates the signatures array with the signature of the transaction after signing.
  #
  # @return [String] The signature of the transaction
  def sign(keypair)
    binary_sig = keypair.sign(message.to_binary).tap do |sig|
      self.signatures << sig
    end
    
    Solana::Utils::Codecs.bytes_to_base58(binary_sig.bytes)
  end
end

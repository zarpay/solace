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
class Solana::Transaction < Solana::SerializableRecord
  # @!const SERIALIZER
  #   @return [Solana::Serializers::TransactionSerializer] The serializer for the transaction
  SERIALIZER = Solana::Serializers::TransactionSerializer

  # @!const DESERIALIZER
  #   @return [Solana::Serializers::TransactionDeserializer] The deserializer for the transaction
  DESERIALIZER = Solana::Serializers::TransactionDeserializer

  # @!attribute [rw] signatures 
  #   @return [Array<String>] Signatures of the transaction (binary)
  attr_accessor :signatures

  # @!attribute [rw] message
  #   @return [Solana::Message] Message of the transaction
  attr_accessor :message

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

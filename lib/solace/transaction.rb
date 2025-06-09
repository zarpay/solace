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
class Solace::Transaction < Solace::SerializableRecord
  # @!const SERIALIZER
  #   @return [Solace::Serializers::TransactionSerializer] The serializer for the transaction
  SERIALIZER = Solace::Serializers::TransactionSerializer

  # @!const DESERIALIZER
  #   @return [Solace::Serializers::TransactionDeserializer] The deserializer for the transaction
  DESERIALIZER = Solace::Serializers::TransactionDeserializer

  # @!attribute [rw] signatures 
  #   @return [Array<String>] Signatures of the transaction (binary)
  attr_accessor :signatures

  # @!attribute [rw] message
  #   @return [Solace::Message] Message of the transaction
  attr_accessor :message

  # Initialize a new transaction
  # 
  # @return [Solace::Transaction] The new transaction object
  def initialize(
    signatures: [], 
    message: Solace::Message.new
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
    
    Solace::Utils::Codecs.bytes_to_base58(binary_sig.bytes)
  end
end

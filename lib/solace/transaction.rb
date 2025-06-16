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

  class << self
    # Deserialize a base64 encoded transaction into a Solace::Transaction object
    #
    # @param io [IO] The IO object containing the binary transaction
    # @return [Solace::Transaction] The deserialized transaction
    def from(io)
      DESERIALIZER.call Solace::Utils::Codecs.base64_to_bytestream(io)
    end
  end

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
  def sign(*keypairs)
    keypairs
      .map { |keypair| keypair.sign(message.to_binary) }
      .tap { |signatures| self.signatures += signatures }
  end
end

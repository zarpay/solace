# encoding: ASCII-8BIT
# frozen_string_literal: true

module Solace
  # Class representing a Solana transaction
  #
  # Transactions are the basic building blocks of Solana. They contain a message and an array of signatures. The
  # message contains the instructions to be executed and the accounts that are used by the instructions. The signatures
  # are the signatures of the accounts that are used by the instructions. This class provides methods for signing,
  # serializing, and deserializing transactions.
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
  # @example
  #   # Create a new transaction
  #   tx = Solace::Transaction.new
  #
  #   # Add a message to the transaction
  #   tx.message = Solace::Message.new(**message_params)
  #
  #   # Sign the transaction
  #   tx.sign(payer_keypair)
  #
  # @since 0.0.1
  class Transaction
    include Solace::Concerns::BinarySerializable

    # @!attribute SERIALIZER
    #   @return [Solace::Serializers::TransactionSerializer] The serializer for the transaction
    SERIALIZER = Solace::Serializers::TransactionSerializer

    # @!attribute DESERIALIZER
    #   @return [Solace::Serializers::TransactionDeserializer] The deserializer for the transaction
    DESERIALIZER = Solace::Serializers::TransactionDeserializer

    # @!attribute SIGNATURE_PLACEHOLDER
    #   @return [String] Placeholder for a signature in the transaction
    SIGNATURE_PLACEHOLDER = Solace::Utils::Codecs.base58_to_binary('1' * 64)

    # @!attribute  [rw] signatures
    #   @return [Array<String>] Signatures of the transaction (binary)
    attr_accessor :signatures

    # @!attribute  [rw] message
    #   @return [Solace::Message] Message of the transaction
    attr_accessor :message

    class << self
      # Deserialize a base64 encoded transaction into a Solace::Transaction object
      #
      # @param base64_tx [String] The base64 encoded transaction
      # @return [Solace::Transaction] The deserialized transaction
      def from(base64_tx)
        DESERIALIZER.new(Solace::Utils::Codecs.base64_to_bytestream(base64_tx)).call
      end
    end

    # Initialize a new transaction
    #
    # @return [Solace::Transaction] The new transaction object
    def initialize(
      signatures: [],
      message: Solace::Message.new
    )
      super()
      @signatures = signatures
      @message = message
    end

    # Sign the transaction
    #
    # Calls sign_and_update_signatures for each keypair passed in.
    #
    # @param keypairs [Array<Solace::Keypair>] The keypairs to sign the transaction with
    # @return [Array<String>] The signatures of the transaction
    def sign(*keypairs)
      keypairs.map { |keypair| sign_and_update_signatures(keypair) }
    end

    private

    # Sign message and update signatures
    #
    # Signs the transaction's message and updates the signatures array with the
    # signature.
    #
    # @return [Array<String>] The signatures of the transaction
    def sign_and_update_signatures(keypair)
      keypair.sign(message.to_binary).tap { |signature| set_signature(keypair.address, signature) }
    end

    # Update the transaction signatures
    #
    # Updates the signatures array according to the accounts of the message.
    #
    # @param public_key [String] The public key of the signer
    # @param signature [String] The signature to insert
    def set_signature(public_key, signature)
      index = message.accounts.index(public_key)

      raise ArgumentError, 'Public key not found in transaction' if index.nil?

      signatures[index] = signature
    end
  end
end

# frozen_string_literal: true

module Solana
  module Serializers
    # =============================
    # Transaction Serializer
    # =============================
    #
    # Serializes a Solana transaction to a binary format.
    class TransactionSerializer < Serializers::Base
      include Solana::Utils

      # @!const SERIALIZATION_STEPS
      #   An ordered list of methods to serialize the transaction
      # 
      # @return [Array] The steps to serialize the transaction
      SERIALIZATION_STEPS = [
        :encode_signatures,
        :encode_message
      ].freeze

      # Initialize a new serializer
      # 
      # @param transaction [Solana::Transaction] The transaction to serialize
      # @return [Solana::TransactionSerializer] The new serializer object
      def initialize(transaction)
        @tx = transaction
      end

      # Serializes the transaction
      # 
      # @return [String] The serialized transaction (base64)
      def call
        bin = SERIALIZATION_STEPS
          .map { |m| send(m) }
          .flatten
          .compact
          .pack("C*")

        Base64.strict_encode64(bin)
      end

      private

      attr_reader :tx

      # Encodes the signatures of the transaction
      # 
      # The BufferLayout is:
      #   - [Number of signatures (compact u16)]
      #   - [Signatures (variable length)]
      #
      # @return [Array<Integer>] The bytes of the encoded signatures
      def encode_signatures
        [Codecs.encode_compact_u16(tx.signatures.size).bytes] + 
        tx.signatures.map { Codecs.base58_to_bytes(_1) }
      end

      # Encodes the message from the transaction
      # 
      # @return [Array<Integer>] The bytes of the encoded message
      def encode_message
        tx.message.to_bytes
      end
    end
  end
end
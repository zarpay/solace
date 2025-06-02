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
        Codecs.encode_compact_u16(tx.signatures.size).bytes + 
        tx.signatures.map { _1.bytes }
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
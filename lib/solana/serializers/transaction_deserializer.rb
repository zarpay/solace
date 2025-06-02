# frozen_string_literal: true

module Solana
  module Serializers 
    # =============================
    # Transaction Deserializer
    # =============================
    #
    # Deserializes a binary transaction into a Solana::Transaction object.
    class TransactionDeserializer < Serializers::Base
      include Solana::Utils

      # @!const DESERIALIZATION_STEPS
      #   An ordered list of methods to deserialize the transaction
      # 
      # @return [Array] The steps to deserialize the transaction
      DESERIALIZATION_STEPS = [
        :next_extract_signatures,
        :next_extract_message
      ]

      # Initialize a new deserializer
      # 
      # @param transaction_base64 [String] The base64 encoded transaction to deserialize
      # @return [Solana::TransactionDeserializer] The new deserializer object
      def initialize(transaction_base64)
        @io = Codecs.base64_to_bytestream(transaction_base64)

        # Initialize transaction object
        @tx = Solana::Transaction.new
      end

      # Deserializes a binary transaction into a Solana::Transaction object.
      # 
      # @return [Solana::Transaction] The deserialized transaction object
      def call
        DESERIALIZATION_STEPS.each { send(_1) }

        raise "End of message not reached. Transaction data is too long." unless io.eof?

        tx
      end

      private

      attr_reader :io, :tx

      # Extract signatures from the transaction
      # 
      # @return [Array] Array of base58 encoded signatures
      def next_extract_signatures
        count, _ = Codecs.decode_compact_u16(io)
        tx.signatures = count.times.map { io.read(64) }
      end

      # Extract the message from the transaction
      # 
      # @return [Solana::Message] The deserialized message instance
      def next_extract_message
        tx.message = Solana::Serializers::MessageDeserializer.call(io)
      end
    end
  end
end
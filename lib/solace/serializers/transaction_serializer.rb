# frozen_string_literal: true

module Solace
  module Serializers
    # Serializes a Solana transaction to a binary format.
    #
    # @since 0.0.1
    class TransactionSerializer < Solace::Serializers::BaseSerializer
      # @!attribute SIGNATURE_PLACEHOLDER
      #   @return [String] Placeholder for a signature in the transaction
      SIGNATURE_PLACEHOLDER = ([0] * 64).pack('C*')

      # @!attribute steps
      #   An ordered list of methods to serialize the transaction
      #
      # @return [Array] The steps to serialize the transaction
      self.steps = %i[
        encode_signatures
        encode_message
      ]

      # Encodes the signatures of the transaction
      #
      # Iterates over the number sum number of signatures and either encodes or sets
      # the placeholder for each expected index in the signatures array.
      #
      # The BufferLayout is:
      #   - [Number of signatures (compact u16)]
      #   - [Signatures (variable length)]
      #
      # @return [Array<Integer>] The bytes of the encoded signatures
      def encode_signatures
        Codecs.encode_compact_u16(record.signatures.size).bytes +
          index_signatures(record.message.num_required_signatures)
      end

      # Encodes the message from the transaction
      #
      # @return [Array<Integer>] The bytes of the encoded message
      def encode_message
        record.message.to_bytes
      end

      private

      # Index the signatures
      #
      # Positions the signatures by expected index and set placeholders for any missing signatures.
      #
      # @param num_required_signatures [Integer] The number of required signatures
      #
      # @return [Array<Integer>] The bytes of the encoded signatures
      def index_signatures(num_required_signatures)
        (0...num_required_signatures).map { (record.signatures[_1] || SIGNATURE_PLACEHOLDER).bytes }
      end
    end
  end
end

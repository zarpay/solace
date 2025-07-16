# frozen_string_literal: true

# =============================
# Transaction Deserializer
# =============================
#
# Deserializes a binary transaction into a Solace::Transaction object.
module Solace
  module Serializers
    class TransactionDeserializer < Solace::Serializers::BaseDeserializer
      # @!attribute record_class
      #   The class of the record being deserialized
      #
      # @return [Class] The class of the record
      self.record_class = Solace::Transaction

      # @!attribute steps
      #   An ordered list of methods to deserialize the transaction
      #
      # @return [Array] The steps to deserialize the transaction
      self.steps = %i[
        next_extract_signatures
        next_extract_message
      ]

      # Extract signatures from the transaction
      #
      # The BufferLayout is:
      #   - [Number of signatures (compact u16)]
      #   - [Signatures (variable length)]
      #
      # @return [Array] Array of base58 encoded signatures
      def next_extract_signatures
        count, = Codecs.decode_compact_u16(io)
        record.signatures = count.times.map { io.read(64) }
      end

      # Extract the message from the transaction
      #
      # The BufferLayout is:
      #   - [Message (variable length)]
      #
      # @return [Solace::Message] The deserialized message instance
      def next_extract_message
        record.message = Solace::Serializers::MessageDeserializer.call(io)
      end
    end
  end
end

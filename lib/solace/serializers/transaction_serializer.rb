# frozen_string_literal: true

# =============================
# Transaction Serializer
# =============================
#
# Serializes a Solana transaction to a binary format.
class Solace::Serializers::TransactionSerializer < Solace::Serializers::BaseSerializer
  # @!attribute steps
  #   An ordered list of methods to serialize the transaction
  # 
  # @return [Array] The steps to serialize the transaction
  self.steps = [
    :encode_signatures,
    :encode_message
  ]

  # Encodes the signatures of the transaction
  # 
  # The BufferLayout is:
  #   - [Number of signatures (compact u16)]
  #   - [Signatures (variable length)]
  #
  # @return [Array<Integer>] The bytes of the encoded signatures
  def encode_signatures
    Codecs.encode_compact_u16(record.signatures.size).bytes + 
    record.signatures.map { _1.bytes }
  end

  # Encodes the message from the transaction
  # 
  # @return [Array<Integer>] The bytes of the encoded message
  def encode_message
    record.message.to_bytes
  end
end

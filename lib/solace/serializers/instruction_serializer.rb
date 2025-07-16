# frozen_string_literal: true

# =============================
# Instruction Serializer
# =============================
#
# Serializes a Solana instruction to a binary format.
module Solace
  module Serializers
    class InstructionSerializer < Solace::Serializers::BaseSerializer
      # @!attribute steps
      #   An ordered list of methods to serialize the instruction
      #
      # @return [Array] The steps to serialize the instruction
      self.steps = %i[
        encode_program_index
        encode_accounts
        encode_data
      ]

      # Encodes the program index of the instruction
      #
      # The BufferLayout is:
      #   - [Program index (u8)]
      #
      # @return [Integer] The bytes of the encoded program index
      def encode_program_index
        record.program_index
      end

      # Encodes the accounts of the instruction
      #
      # The BufferLayout is:
      #   - [Number of accounts (compact u16)]
      #   - [Accounts (variable length u8)]
      #
      # @return [Array<Integer>] The bytes of the encoded accounts
      def encode_accounts
        Codecs.encode_compact_u16(record.accounts.size).bytes + record.accounts
      end

      # Encodes the data of the instruction
      #
      # The BufferLayout is:
      #   - [Number of data bytes (compact u16)]
      #   - [Data bytes (variable length u8)]
      #
      # @return [Array<Integer>] The bytes of the encoded data
      def encode_data
        Codecs.encode_compact_u16(record.data.size).bytes + record.data
      end
    end
  end
end

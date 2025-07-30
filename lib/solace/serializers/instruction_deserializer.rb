# frozen_string_literal: true

# =============================
# Instruction Deserializer
# =============================
#
# Deserializes a binary instruction into a Solace::Instruction object.
module Solace
  module Serializers
    # !@class InstructionDeserializer
    #
    # @return [Class]
    class InstructionDeserializer < Solace::Serializers::BaseDeserializer
      # @!attribute record_class
      #   The class of the record being deserialized
      #
      # @return [Class] The class of the record
      self.record_class = Solace::Instruction

      # @!attribute steps
      #   An ordered list of methods to deserialize the instruction
      #
      # @return [Array] The steps to deserialize the instruction
      self.steps = %i[
        next_extract_program_index
        next_extract_accounts
        next_extract_data
      ]

      # Extracts the program index from the instruction
      #
      # The BufferLayout is:
      #   - [Program index (1 byte)]
      #
      # @return [Integer] The program index
      def next_extract_program_index
        record.program_index = io.read(1).ord
      end

      # Extracts the accounts from the instruction
      #
      # The BufferLayout is:
      #   - [Number of accounts (compact u16)]
      #   - [Accounts (variable length u8)]
      #
      # @return [Array] The accounts
      def next_extract_accounts
        length, = Codecs.decode_compact_u16(io)
        record.accounts = io.read(length).unpack('C*')
      end

      # Extracts the instruction data from the instruction
      #
      # The BufferLayout is:
      #   - [Number of data bytes (compact u16)]
      #   - [Data bytes (variable length u8)]
      #
      # @return [Array] The instruction data
      def next_extract_data
        length, = Codecs.decode_compact_u16(io)
        record.data = io.read(length).unpack('C*')
      end
    end
  end
end

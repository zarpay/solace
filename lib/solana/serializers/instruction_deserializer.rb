# frozen_string_literal: true

module Solana
  module Serializers
    # =============================
    # Instruction Deserializer
    # =============================
    # 
    # Deserializes a binary instruction into a Solana::Instruction object.
    class InstructionDeserializer < Serializers::Base

      # @!const DESERIALIZATION_STEPS
      #   An ordered list of methods to deserialize the instruction
      # 
      # @return [Array] The steps to deserialize the instruction
      DESERIALIZATION_STEPS = [
        :next_extract_program_index,
        :next_extract_accounts,
        :next_extract_data
      ]

      # Initialize a new deserializer
      # 
      # @param io [IO or StringIO] The input to read bytes from.
      # @return [Solana::InstructionDeserializer] The new deserializer object
      def initialize(io)
        @io = io

        # Initialize instruction object
        @ix = Solana::Instruction.new
      end

      # Deserializes the instruction from a binary format
      # 
      # @return [Solana::Instruction] The deserialized instruction
      def call
        DESERIALIZATION_STEPS.each { send(_1) }

        ix
      end

      private

      attr_reader :io, :ix

      # Extracts the program index from the instruction
      # 
      # The BufferLayout is:
      #   - [Program index (1 byte)]
      # 
      # @return [Integer] The program index
      def next_extract_program_index
        ix.program_index = io.read(1).ord
      end

      # Extracts the accounts from the instruction
      # 
      # The BufferLayout is:
      #   - [Number of accounts (compact u16)]
      #   - [Accounts (variable length u8)]
      # 
      # @return [Array] The accounts
      def next_extract_accounts
        length, _ = Codecs.decode_compact_u16(io)
        ix.accounts = io.read(length).unpack("C*")
      end

      # Extracts the instruction data from the instruction
      # 
      # The BufferLayout is:
      #   - [Number of data bytes (compact u16)]
      #   - [Data bytes (variable length u8)]
      # 
      # @return [Array] The instruction data
      def next_extract_data
        length, _ = Codecs.decode_compact_u16(io)
        ix.data = io.read(length).unpack("C*")
      end
    end
  end
end
  
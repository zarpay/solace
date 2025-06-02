# frozen_string_literal: true

module Solana
  module Serializers
    # =============================
    # Instruction Serializer
    # =============================
    #
    # Serializes a Solana instruction to a binary format.
    class InstructionSerializer < Serializers::Base
      include Solana::Utils

      # @!const SERIALIZATION_STEPS
      #   An ordered list of methods to serialize the instruction
      # 
      # @return [Array] The steps to serialize the instruction
      SERIALIZATION_STEPS = [
        :encode_program_index,
        :encode_accounts,
        :encode_data
      ].freeze
      
      # Initialize a new serializer
      # 
      # @param instruction [Solana::Instruction] The instruction to serialize
      # @return [Solana::InstructionSerializer] The new serializer object
      def initialize(instruction)
        @ix = instruction
      end

      private

      attr_reader :ix

      # Encodes the program index of the instruction
      # 
      # The BufferLayout is:
      #   - [Program index (u8)]
      # 
      # @return [Integer] The bytes of the encoded program index
      def encode_program_index
        ix.program_index
      end

      # Encodes the accounts of the instruction
      # 
      # The BufferLayout is:
      #   - [Number of accounts (compact u16)]
      #   - [Accounts (variable length u8)]
      # 
      # @return [Array<Integer>] The bytes of the encoded accounts
      def encode_accounts
        Codecs.encode_compact_u16(ix.accounts.size).bytes + ix.accounts
      end

      # Encodes the data of the instruction
      # 
      # The BufferLayout is:
      #   - [Number of data bytes (compact u16)]
      #   - [Data bytes (variable length u8)]
      # 
      # @return [Array<Integer>] The bytes of the encoded data
      def encode_data
        Codecs.encode_compact_u16(ix.data.size).bytes + ix.data
      end
    end
  end
end
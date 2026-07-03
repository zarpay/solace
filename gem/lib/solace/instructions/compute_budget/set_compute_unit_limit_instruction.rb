# frozen_string_literal: true

module Solace
  module Instructions
    module ComputeBudget
      # Instruction for setting the compute unit limit.
      #
      # This instruction is used to set the maximum number of compute units a
      # transaction may consume. Together with the compute unit price, it
      # determines the priority fee the transaction pays.
      #
      # @example Build a SetComputeUnitLimit instruction
      #   instruction = Solace::Instructions::ComputeBudget::SetComputeUnitLimitInstruction.build(
      #     units: 200_000,
      #     program_index: 1
      #   )
      #
      # @since 0.1.7
      class SetComputeUnitLimitInstruction
        # @!attribute [Array<Integer>] INSTRUCTION_INDEX
        #   Instruction index for the Compute Budget Program's SetComputeUnitLimit instruction.
        INSTRUCTION_INDEX = [2].freeze

        # Builds a Solace::Instruction for setting the compute unit limit
        #
        # @param units [Integer] Maximum compute units the transaction may consume
        # @param program_index [Integer] Index of the Compute Budget program in the transaction's accounts
        # @return [Solace::Instruction]
        def self.build(units:, program_index:)
          Solace::Instruction.new.tap do |ix|
            ix.program_index = program_index
            ix.accounts      = []
            ix.data          = data(units)
          end
        end

        # Instruction data for a set compute unit limit instruction
        #
        # The BufferLayout is:
        #   - [Instruction Index (1 byte)]
        #   - [Compute unit limit (4 bytes little-endian u32)]
        #
        # @param units [Integer] Maximum compute units the transaction may consume
        # @return [Array<Integer>] 1-byte instruction index + 4-byte limit
        def self.data(units)
          INSTRUCTION_INDEX + Solace::Utils::Codecs.encode_le_u32(units).bytes
        end
      end
    end
  end
end

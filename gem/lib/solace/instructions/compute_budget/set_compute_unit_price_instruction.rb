# frozen_string_literal: true

module Solace
  module Instructions
    # The ComputeBudget module contains instruction builders for the Compute Budget Program.
    #
    # The Compute Budget program prices and provisions a transaction's execution. Its
    # instructions take no accounts; each encodes a directive the runtime reads when
    # scheduling and executing the transaction, such as the priority fee attached to it.
    #
    # This module contains classes that build the low-level instruction data required
    # to interact with the Compute Budget Program.
    #
    # @see https://docs.solana.com/developing/programming-model/runtime#compute-budget
    # @since 0.1.7
    module ComputeBudget
      # Instruction for setting the compute unit price.
      #
      # This instruction is used to set the price (in micro-lamports per compute unit)
      # a transaction pays as a priority fee, which validators use to order it during
      # congestion.
      #
      # @example Build a SetComputeUnitPrice instruction
      #   instruction = Solace::Instructions::ComputeBudget::SetComputeUnitPriceInstruction.build(
      #     micro_lamports: 50_000,
      #     program_index: 1
      #   )
      #
      # @since 0.1.7
      class SetComputeUnitPriceInstruction
        # @!attribute [Array<Integer>] INSTRUCTION_INDEX
        #   Instruction index for the Compute Budget Program's SetComputeUnitPrice instruction.
        INSTRUCTION_INDEX = [3].freeze

        # Builds a Solace::Instruction for setting the compute unit price
        #
        # @param micro_lamports [Integer] Price per compute unit (in micro-lamports)
        # @param program_index [Integer] Index of the Compute Budget program in the transaction's accounts
        # @return [Solace::Instruction]
        def self.build(micro_lamports:, program_index:)
          Solace::Instruction.new.tap do |ix|
            ix.program_index = program_index
            ix.accounts      = []
            ix.data          = data(micro_lamports)
          end
        end

        # Instruction data for a set compute unit price instruction
        #
        # The BufferLayout is:
        #   - [Instruction Index (1 byte)]
        #   - [Price (8 bytes little-endian u64)]
        #
        # @param micro_lamports [Integer] Price per compute unit (in micro-lamports)
        # @return [Array<Integer>] 1-byte instruction index + 8-byte price
        def self.data(micro_lamports)
          INSTRUCTION_INDEX + Solace::Utils::Codecs.encode_le_u64(micro_lamports).bytes
        end
      end
    end
  end
end

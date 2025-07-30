# frozen_string_literal: true

module Solace
  module Instructions
    module SystemProgram
      # Instruction for transferring SOL.
      #
      # This instruction is used to transfer SOL from one account to another.
      #
      # @example Build a Transfer instruction
      #   instruction = Solace::Instructions::SystemProgram::TransferInstruction.build(
      #     lamports: 100,
      #     to_index: 1,
      #     from_index: 2,
      #     program_index: 3
      #   )
      #
      # @since 0.0.2
      class TransferInstruction
        # Instruction ID for System Transfer
        INSTRUCTION_ID = [2, 0, 0, 0].freeze

        # Builds a Solace::Instruction for transferring SOL
        #
        # @param lamports [Integer] Amount to transfer (in lamports)
        # @param to_index [Integer] Index of the recipient in the transaction's accounts
        # @param from_index [Integer] Index of the sender in the transaction's accounts
        # @param program_index [Integer] Index of the program in the transaction's accounts (default: 2)
        # @return [Solace::Instruction]
        def self.build(
          lamports:,
          to_index:,
          from_index:,
          program_index: 2
        )
          Instruction.new.tap do |ix|
            ix.program_index = program_index
            ix.accounts = [from_index, to_index]
            ix.data = data(lamports)
          end
        end

        # Instruction data for a transfer instruction
        #
        # The BufferLayout is:
        #   - [Instruction ID (4 bytes)]
        #   - [Amount (8 bytes little-endian u64)]
        #
        # @param lamports [Integer] Amount to transfer (in lamports)
        # @return [Array] 4-byte instruction ID + 8-byte amount
        def self.data(lamports)
          INSTRUCTION_ID +
            Utils::Codecs.encode_le_u64(lamports).bytes
        end
      end
    end
  end
end

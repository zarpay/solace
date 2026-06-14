# frozen_string_literal: true

module Solace
  module Instructions
    # The SplToken module contains instruction builders for the SPL Token Program.
    #
    # The SPL Token Program is Solana's standard for fungible and non-fungible tokens.
    # It provides instructions for creating token mints, creating token accounts,
    # minting tokens, transferring tokens, and managing token authorities.
    #
    # This module contains classes that build the low-level instruction data required
    # to interact with the SPL Token Program. Each class corresponds to a specific
    # instruction in the program.
    #
    # @example Building a transfer instruction
    #   instruction = Solace::Instructions::SplToken::TransferInstruction.build(
    #     source_index: 0,
    #     destination_index: 1,
    #     owner_index: 2,
    #     program_index: 3,
    #     amount: 1_000_000
    #   )
    #
    # @see https://spl.solana.com/token
    # @since 0.0.2
    module SplToken
      # Instruction for transferring SPL tokens.
      #
      # This instruction is used to transfer SPL tokens from one token account to another.
      #
      # @example Build a Transfer instruction
      #   instruction = Solace::Instructions::SplToken::TransferInstruction.build(
      #     amount: 100,
      #     owner_index: 1,
      #     source_index: 2,
      #     destination_index: 3,
      #     program_index: 4
      #   )
      #
      # @since 0.0.2
      class TransferInstruction
        # @!attribute [Array<Integer>] INSTRUCTION_INDEX
        #   Instruction index for SPL Token Program's Transfer instruction.
        INSTRUCTION_INDEX = [3].freeze

        # Builds a Transfer instruction.
        #
        # @param amount [Integer] The amount of tokens to transfer.
        # @param source_index [Integer] The index of the source token account.
        # @param destination_index [Integer] The index of the destination token account.
        # @param owner_index [Integer] The index of the source account's owner.
        # @param program_index [Integer] The index of the SPL Token Program.
        # @return [Solace::Instruction]
        def self.build(
          amount:,
          owner_index:,
          source_index:,
          destination_index:,
          program_index:
        )
          Solace::Instruction.new.tap do |ix|
            ix.program_index = program_index
            ix.accounts      = [source_index, destination_index, owner_index]
            ix.data          = data(amount)
          end
        end

        # Builds the data for a Transfer instruction.
        #
        # The BufferLayout is:
        #   - [Instruction Index (1 byte)]
        #   - [Amount (8 bytes)]
        #
        # @param amount [Integer] The amount of tokens to transfer.
        # @return [Array<Integer>] 1-byte instruction index + 8-byte amount
        def self.data(amount)
          INSTRUCTION_INDEX + Solace::Utils::Codecs.encode_le_u64(amount).bytes
        end
      end
    end
  end
end

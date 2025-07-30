# frozen_string_literal: true

module Solace
  module Instructions
    module SplToken
      # Instruction for minting tokens to a token account.
      #
      # This instruction is used to mint tokens to a token account for a given mint and owner.
      #
      # @example Build a MintTo instruction
      #   instruction = Solace::Instructions::SplToken::MintToInstruction.build(
      #     amount: 100,
      #     mint_index: 1,
      #     mint_authority_index: 2,
      #     destination_index: 3,
      #     program_index: 4
      #   )
      #
      # @since 0.0.2
      class MintToInstruction
        # @!attribute [Array<Integer>] INSTRUCTION_INDEX
        #   Instruction index for SPL Token Program's MintTo instruction.
        INSTRUCTION_INDEX = [7].freeze

        # Builds a MintTo instruction.
        #
        # @param amount [Integer] The amount of tokens to mint.
        # @param mint_index [Integer] The index of the mint account.
        # @param destination_index [Integer] The index of the token account to mint to.
        # @param mint_authority_index [Integer] The index of the mint authority account.
        # @param program_index [Integer] The index of the SPL Token Program.
        # @return [Solace::Instruction]
        def self.build(
          amount:,
          mint_index:,
          mint_authority_index:,
          destination_index:,
          program_index:
        )
          Solace::Instruction.new.tap do |ix|
            ix.program_index = program_index
            ix.accounts = [mint_index, destination_index, mint_authority_index]
            ix.data = data(amount)
          end
        end

        # Builds the data for a MintTo instruction.
        #
        # The BufferLayout is:
        #   - [Instruction Index (1 byte)]
        #   - [Amount (8 bytes)]
        #
        # @param amount [Integer] The amount of tokens to mint.
        # @return [Array] 1-byte instruction index + 8-byte amount
        def self.data(amount)
          INSTRUCTION_INDEX + Solace::Utils::Codecs.encode_le_u64(amount).bytes
        end
      end
    end
  end
end

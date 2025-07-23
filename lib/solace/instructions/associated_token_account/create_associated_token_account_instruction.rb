# frozen_string_literal: true

module Solace
  module Instructions
    module AssociatedTokenAccount
      # A class to build the CreateAssociatedTokenAccount instruction for the Associated Token Account Program.
      # This is a special "all-in-one" instruction that creates and initializes the account.
      class CreateAssociatedTokenAccountInstruction
        # !@const INSTRUCTION_INDEX
        #   Instruction index for CreateAssociatedTokenAccount
        #
        # @return [Array<Integer>]
        INSTRUCTION_INDEX = [0].freeze

        # Builds a CreateAssociatedTokenAccount instruction.
        #
        # The on-chain program requires accounts in a specific order:
        # 1. [writable, signer] Funder: The account paying for the rent.
        # 2. [writable] ATA: The new Associated Token Account to be created.
        # 3. [readonly] Owner: The wallet that will own the new ATA.
        # 4. [readonly] Mint: The token mint for the new ATA.
        # 5. [readonly] System Program: Required to create the account.
        # 6. [readonly] SPL Token Program: Required to initialize the account.
        #
        # @param funder_index [Integer] Index of the funding account (payer).
        # @param associated_token_account_index [Integer] Index of the Associated Token Account to be created.
        # @param owner_index [Integer] Index of the wallet that will own the new ATA.
        # @param mint_index [Integer] Index of the token mint.
        # @param system_program_index [Integer] Index of the System Program.
        # @param token_program_index [Integer] Index of the SPL Token Program.
        # @param program_index [Integer] Index of the Associated Token Program itself.
        # @return [Solace::Instruction]
        def self.build(
          funder_index:,
          associated_token_account_index:,
          owner_index:,
          mint_index:,
          system_program_index:,
          token_program_index:,
          program_index:
        )
          Solace::Instruction.new.tap do |ix|
            ix.program_index = program_index
            ix.accounts = [
              funder_index,
              associated_token_account_index,
              owner_index,
              mint_index,
              system_program_index,
              token_program_index
            ]
            # This instruction has no instruction data/index byte.
            ix.data = data
          end
        end

        # Data for a CreateAssociatedTokenAccount instruction
        #
        # The BufferLayout is:
        #   - [Instruction Index (1 byte)]
        #
        # @return [Array] 1-byte instruction index
        def self.data
          INSTRUCTION_INDEX
        end
      end
    end
  end
end
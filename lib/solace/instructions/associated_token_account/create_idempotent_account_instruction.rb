# frozen_string_literal: true

module Solace
  module Instructions
    # The AssociatedTokenAccount module contains instruction builders for the
    # Associated Token Account Program.
    #
    # The Associated Token Account (ATA) Program provides a deterministic way to
    # derive token account addresses for a given wallet and mint. This ensures that
    # each wallet has a single, predictable token account for each token type.
    #
    # @see https://spl.solana.com/associated-token-account
    # @since 0.1.3
    module AssociatedTokenAccount
      # Instruction for creating an Associated Token Account idempotently.
      #
      # This instruction behaves like `CreateAccountInstruction`, but will not fail
      # if the account already exists. This is useful for scenarios where the existence of the
      # account is uncertain, and you want to ensure it exists without causing an error.
      #
      # @example Build a CreateIdempotentAccount instruction
      #   instruction = Solace::Instructions::AssociatedTokenAccount::CreateIdempotentAccountInstruction.build(
      #     funder_index: 0,
      #     associated_token_account_index: 1,
      #     owner_index: 2,
      #     mint_index: 3,
      #     system_program_index: 4,
      #     token_program_index: 5,
      #     program_index: 6
      #   )
      #
      # @see CreateAccountInstruction
      class CreateIdempotentAccountInstruction < CreateAccountInstruction
        # !@const INSTRUCTION_INDEX
        #   Instruction index for CreateIdempotentAccount
        #
        # @return [Array<Integer>]
        INSTRUCTION_INDEX = [1].freeze

        # Data for a CreateAccount instruction
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

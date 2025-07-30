# frozen_string_literal: true

# lib/solace/instructions/spl_token/initialize_account_instruction.rb

module Solace
  module Instructions
    module SplToken
      # Instruction for initializing a new token account.
      #
      # This instruction is used to initialize a new token account for a given mint and owner. It
      # is used in conjunction with the CreateAccount instruction to create and initialize a new
      # token account. Note that the AssociatedTokenAccount::CreateAssociatedTokenAccountInstruction
      # is a special "all-in-one" instruction that creates and initializes the account in a single
      # instruction.
      #
      # @example Build an InitializeAccount instruction
      #   instruction = Solace::Instructions::SplToken::InitializeAccountInstruction.build(
      #     account_index: 0,
      #     mint_index: 1,
      #     owner_index: 2,
      #     rent_sysvar_index: 3,
      #     program_index: 4
      #   )
      #
      # @see Solace::Instructions::AssociatedTokenAccount::CreateAssociatedTokenAccountInstruction
      # @see Solace::Instructions::SystemProgram::CreateAccountInstruction
      # @since 0.0.2
      class InitializeAccountInstruction
        # @!attribute [Array<Integer>] INSTRUCTION_INDEX
        #   Instruction index for SPL Token Program's InitializeAccount instruction.
        INSTRUCTION_INDEX = [1].freeze

        # Builds a SPLToken::InitializeAccount instruction.
        #
        # @param account_index [Integer] Index of the new token account in the transaction's accounts.
        # @param mint_index [Integer] Index of the mint account in the transaction's accounts.
        # @param owner_index [Integer] Index of the owner of the new account in the transaction's accounts.
        # @param rent_sysvar_index [Integer] Index of the Rent Sysvar in the transaction's accounts.
        # @param program_index [Integer] Index of the SPL Token program in the transaction's accounts.
        # @return [Solace::Instruction]
        def self.build(
          account_index:,
          mint_index:,
          owner_index:,
          rent_sysvar_index:,
          program_index:
        )
          Solace::Instruction.new.tap do |ix|
            ix.program_index = program_index
            ix.accounts = [account_index, mint_index, owner_index, rent_sysvar_index]
            ix.data = data
          end
        end

        # Builds the data for a SPLToken::InitializeAccount instruction.
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

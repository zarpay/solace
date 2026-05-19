# frozen_string_literal: true

module Solace
  module Instructions
    module Token2022
      # Instruction for initializing a new Token-2022 token account.
      #
      # Used in conjunction with the SystemProgram::CreateAccount instruction
      # to create and initialize a new token account. For the common case of
      # an associated token account, prefer
      # {AssociatedTokenAccount::CreateAccountInstruction}.
      #
      # @example Build an InitializeAccount instruction
      #   instruction = Solace::Instructions::Token2022::InitializeAccountInstruction.build(
      #     account_index: 0,
      #     mint_index: 1,
      #     owner_index: 2,
      #     rent_sysvar_index: 3,
      #     program_index: 4
      #   )
      #
      # @since 0.1.5
      class InitializeAccountInstruction
        # @!attribute [Array<Integer>] INSTRUCTION_INDEX
        #   Instruction index for Token-2022's InitializeAccount instruction.
        INSTRUCTION_INDEX = [1].freeze

        # Builds a Token2022::InitializeAccount instruction.
        #
        # @param account_index [Integer] Index of the new token account in the transaction's accounts.
        # @param mint_index [Integer] Index of the mint account in the transaction's accounts.
        # @param owner_index [Integer] Index of the owner of the new account in the transaction's accounts.
        # @param rent_sysvar_index [Integer] Index of the Rent Sysvar in the transaction's accounts.
        # @param program_index [Integer] Index of the Token-2022 program in the transaction's accounts.
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

        # Builds the data for a Token2022::InitializeAccount instruction.
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

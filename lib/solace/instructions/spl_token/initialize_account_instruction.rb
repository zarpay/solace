# frozen_string_literal: true

# lib/solace/instructions/spl_token/initialize_account_instruction.rb

module Solace
  module Instructions
    module SplToken
      # A class to build the InitializeAccount instruction for the SPL Token Program.
      class InitializeAccountInstruction
        # @!const [Array<Integer>] INSTRUCTION_INDEX
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

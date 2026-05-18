# frozen_string_literal: true

module Solace
  module Instructions
    module Token2022
      # Instruction builder for Token-2022 CloseAccount.
      #
      # Closes a Token-2022 token account and transfers all remaining lamports
      # to a destination account. The token account must have a balance of zero.
      #
      # Instruction discriminator: 9
      #
      # Accounts:
      # 1. [writable] Token account to close
      # 2. [writable] Destination account to receive lamports
      # 3. [signer]   Account authority
      #
      # @since 0.1.5
      class CloseAccountInstruction
        # Instruction discriminator for CloseAccount
        INSTRUCTION_DISCRIMINATOR = [9].freeze

        # Builds a CloseAccount instruction.
        #
        # @param account_index [Integer] Index of the token account to close
        # @param destination_index [Integer] Index of the destination account
        # @param authority_index [Integer] Index of the account authority
        # @param program_index [Integer] Index of the Token-2022 program
        # @return [Solace::Instruction] The constructed instruction
        def self.build(account_index:, destination_index:, authority_index:, program_index:)
          Solace::Instruction.new.tap do |ix|
            ix.program_index = program_index
            ix.accounts = [account_index, destination_index, authority_index]
            ix.data = data
          end
        end

        # Builds the data for a CloseAccount instruction.
        #
        # The BufferLayout is:
        #   - [Instruction Index (1 byte)]
        #
        # @return [Array] 1-byte instruction index
        def self.data
          INSTRUCTION_DISCRIMINATOR
        end
      end
    end
  end
end

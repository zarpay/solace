# frozen_string_literal: true

module Solace
  module Instructions
    module SystemProgram
      # !@class CreateAccountInstruction
      #
      # A class representing a SystemProgram::CreateAccount instruction
      #
      # @return [Class]
      class CreateAccountInstruction
        # !@const INSTRUCTION_INDEX
        #   Instruction index for SystemProgram::CreateAccount
        #   This is the same across all Solana clusters
        # @return [Array<Integer>]
        INSTRUCTION_INDEX = [0, 0, 0, 0].freeze

        # Builds a SystemProgram::CreateAccount instruction
        #
        # @param space [Integer] Number of bytes to allocate for the new account
        # @param lamports [Integer] Amount of lamports to fund the new account
        # @param owner [String] The program_id of the owner of the new account
        # @param from_index [Integer] Index of the funding account (payer) in the transaction's accounts
        # @param new_account_index [Integer] Index of the new account to create in the transaction's accounts
        # @param system_program_index [Integer] Index of the system program in the transaction's accounts (default: 2)
        # @return [Solace::Instruction]
        #
        def self.build(
          space:,
          lamports:,
          from_index:,
          new_account_index:,
          owner: Solace::Constants::SYSTEM_PROGRAM_ID,
          system_program_index: 2
        )
          Solace::Instruction.new.tap do |ix|
            ix.program_index = system_program_index
            ix.accounts = [from_index, new_account_index]
            ix.data = data(lamports, space, owner)
          end
        end
        # rubocop:enable Metrics/ParameterLists

        # Builds the data for a SystemProgram::CreateAccount instruction
        #
        # The BufferLayout is:
        #   - [Instruction Index (4 bytes)]
        #   - [Lamports (8 bytes)]
        #   - [Space (8 bytes)]
        #   - [Owner (32 bytes)]
        #
        # @param lamports [Integer] Amount of lamports to fund the new account
        # @param space [Integer] Number of bytes to allocate for the new account
        # @param owner [String] The program_id of the owner of the new account
        # @return [Array] 4-byte instruction index + 8-byte lamports + 8-byte space + 32-byte owner
        def self.data(lamports, space, owner)
          INSTRUCTION_INDEX +
            Solace::Utils::Codecs.encode_le_u64(lamports).bytes +
            Solace::Utils::Codecs.encode_le_u64(space).bytes +
            Solace::Utils::Codecs.base58_to_bytes(owner)
        end
      end
    end
  end
end

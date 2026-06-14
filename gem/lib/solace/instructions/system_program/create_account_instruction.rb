# frozen_string_literal: true

module Solace
  # The Instructions module contains low-level instruction builders for Solana programs.
  #
  # Instructions are the fundamental building blocks of Solana transactions. Each
  # instruction represents a single operation to be executed by an on-chain program.
  # The classes in this module build the binary instruction data and specify the
  # accounts required for each operation.
  #
  # Instructions are organized by program:
  # - {Solace::Instructions::SystemProgram} - System Program instructions
  # - {Solace::Instructions::SplToken} - SPL Token Program instructions
  # - {Solace::Instructions::AssociatedTokenAccount} - Associated Token Account Program instructions
  #
  # Being a low-level primitive, you must build instructions manually.
  #
  # @example Building a system transfer instruction
  #
  #   # Assuming the transaction's accounts are ordered as follows:
  #   accounts = %w[from_address to_address system_program_id]
  #
  #   # Build the instruction by specifying the account indices directly
  #   instruction = Solace::Instructions::SystemProgram::TransferInstruction.build(
  #     from_index: 0,
  #     to_index: 1,
  #     program_index: 2,
  #     lamports: 1_000_000
  #   )
  #
  # @see Solace::Instruction
  # @see Solace::Composers
  # @since 0.0.1
  module Instructions
    module SystemProgram
      # Instruction for creating a new account.
      #
      # This instruction is used to create a new account for a given program.
      #
      # @example Build a CreateAccount instruction
      #   instruction = Solace::Instructions::SystemProgram::CreateAccountInstruction.build(
      #     space: 1024,
      #     lamports: 1000,
      #     from_index: 0,
      #     new_account_index: 1,
      #     owner: owner.address,
      #     system_program_index: 2
      #   )
      #
      # @since 0.0.2
      class CreateAccountInstruction
        # @!attribute [Array<Integer>] INSTRUCTION_INDEX
        #   Instruction index for SystemProgram::CreateAccount
        #   This is the same across all Solana clusters
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
            ix.accounts      = [from_index, new_account_index]
            ix.data          = data(lamports, space, owner)
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

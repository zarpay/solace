# frozen_string_literal: true

module Solace
  module Instructions
    module SplToken
      # Instruction for initializing a new mint.
      #
      # This instruction is used to initialize a new mint for a given token. It is used in conjunction with the SystemProgram::CreateAccount
      # instruction to create and initialize a new mint account.
      #
      # @example Build an InitializeMint instruction
      #   instruction = Solace::Instructions::SplToken::InitializeMintInstruction.build(
      #     decimals: 6,
      #     mint_authority: mint_authority.address,
      #     freeze_authority: freeze_authority.address,
      #     rent_sysvar_index: 2,
      #     mint_account_index: 1,
      #     program_index: 3
      #   )
      #
      # @see Solace::Instructions::SystemProgram::CreateAccountInstruction
      # @since 0.0.2
      class InitializeMintInstruction
        # Instruction index for Initialize Mint
        INSTRUCTION_INDEX = [0].freeze

        # Builds a Solace::Instruction for initializing an SPL Token Program mint
        #
        # The BufferLayout is:
        #   - [Instruction Index (1 byte)]
        #   - [Decimals (1 byte)]
        #   - [Mint authority (32 bytes)]
        #   - [Freeze authority option (1 byte)]
        #   - [Freeze authority (32 bytes)]
        #
        # @param decimals [Integer] Number of decimals for the token
        # @param mint_authority [String] Public key of the mint authority
        # @param freeze_authority [String, nil] Public key of the freeze authority
        # @param rent_sysvar_index [Integer] Index of the rent sysvar in the transaction's accounts
        # @param mint_account_index [Integer] Index of the mint account in the transaction's accounts
        # @param program_index [Integer] Index of the SPL Token Program in the transaction's accounts (default: 3)
        # @return [Solace::Instruction]
        def self.build(
          decimals:,
          mint_authority:,
          rent_sysvar_index:,
          mint_account_index:,
          freeze_authority: nil,
          program_index: 2
        )
          Solace::Instruction.new.tap do |ix|
            ix.program_index = program_index
            ix.accounts = [mint_account_index, rent_sysvar_index]
            ix.data = data(decimals, mint_authority, freeze_authority)
          end
        end

        # Instruction data for an initialize mint instruction
        #
        # The BufferLayout is:
        #   - [Instruction Index (1 byte)]
        #   - [Decimals (1 byte)]
        #   - [Mint authority (32 bytes)]
        #   - [Freeze authority option (33 byte)]
        #
        # @param decimals [Integer] Number of decimals for the token
        # @param mint_authority [String] Public key of the mint authority
        # @param freeze_authority [String, nil] Public key of the freeze authority
        # @return [Array<u8>] The instruction data
        def self.data(decimals, mint_authority, freeze_authority)
          INSTRUCTION_INDEX +
            [decimals] +
            Solace::Utils::Codecs.base58_to_bytes(mint_authority) +
            (
              if freeze_authority
                [1] + Solace::Utils::Codecs.base58_to_bytes(freeze_authority)
              else
                [0]
              end
            )
        end
      end
    end
  end
end

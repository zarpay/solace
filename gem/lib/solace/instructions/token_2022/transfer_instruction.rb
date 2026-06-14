# frozen_string_literal: true

module Solace
  module Instructions
    # The Token2022 module contains instruction builders for the Token-2022 Program
    # (formerly Token Extensions, +TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb+).
    #
    # Token-2022 is wire-compatible with the legacy SPL Token program for its
    # base instructions (Transfer, TransferChecked, CloseAccount, MintTo,
    # InitializeMint, InitializeAccount). The instruction discriminators and
    # data layouts are identical; only the program the instruction targets
    # differs. These builders are duplicated from the {SplToken} namespace so
    # that each instruction is unambiguously bound to a single on-chain program.
    #
    # @see Solace::Instructions::SplToken
    # @since 0.1.5
    module Token2022
      # Instruction for transferring tokens via the Token-2022 program.
      #
      # @example Build a Transfer instruction
      #   instruction = Solace::Instructions::Token2022::TransferInstruction.build(
      #     amount: 100,
      #     owner_index: 1,
      #     source_index: 2,
      #     destination_index: 3,
      #     program_index: 4
      #   )
      #
      # @since 0.1.5
      class TransferInstruction
        # @!attribute [Array<Integer>] INSTRUCTION_INDEX
        #   Instruction index for Token-2022's Transfer instruction.
        INSTRUCTION_INDEX = [3].freeze

        # Builds a Transfer instruction.
        #
        # @param amount [Integer] The amount of tokens to transfer.
        # @param source_index [Integer] The index of the source token account.
        # @param destination_index [Integer] The index of the destination token account.
        # @param owner_index [Integer] The index of the source account's owner.
        # @param program_index [Integer] The index of the Token-2022 Program.
        # @return [Solace::Instruction]
        def self.build(
          amount:,
          owner_index:,
          source_index:,
          destination_index:,
          program_index:
        )
          Solace::Instruction.new.tap do |ix|
            ix.program_index = program_index
            ix.accounts = [source_index, destination_index, owner_index]
            ix.data = data(amount)
          end
        end

        # Builds the data for a Transfer instruction.
        #
        # The BufferLayout is:
        #   - [Instruction Index (1 byte)]
        #   - [Amount (8 bytes)]
        #
        # @param amount [Integer] The amount of tokens to transfer.
        # @return [Array<Integer>] 1-byte instruction index + 8-byte amount
        def self.data(amount)
          INSTRUCTION_INDEX + Solace::Utils::Codecs.encode_le_u64(amount).bytes
        end
      end
    end
  end
end

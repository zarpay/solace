# frozen_string_literal: true

module Solace
  module Instructions
    module Token2022
      # Instruction for transferring Token-2022 tokens with decimal validation.
      #
      # @example Build a TransferChecked instruction
      #   instruction = Solace::Instructions::Token2022::TransferCheckedInstruction.build(
      #     amount: 100,
      #     decimals: 6,
      #     to_index: 1,
      #     from_index: 2,
      #     mint_index: 3,
      #     authority_index: 4,
      #     program_index: 5
      #   )
      #
      # @since 0.1.5
      class TransferCheckedInstruction
        # Token-2022 instruction index for Transfer Checked
        INSTRUCTION_INDEX = [12].freeze

        # Builds a Solace::Instruction for transferring Token-2022 tokens.
        #
        # The BufferLayout is:
        #   - [Instruction Index (1 byte)]
        #   - [Amount (8 bytes little-endian u64)]
        #   - [Decimals (1 byte)]
        #
        # @param amount [Integer] Amount to transfer (in tokens, according to mint's decimals)
        # @param decimals [Integer] Number of decimals for the token
        # @param to_index [Integer] Index of the destination token account in the transaction's accounts
        # @param from_index [Integer] Index of the source token account in the transaction's accounts
        # @param mint_index [Integer] Index of the mint in the transaction's accounts
        # @param authority_index [Integer] Index of the authority (owner) in the transaction's accounts
        # @param program_index [Integer] Index of the Token-2022 Program in the transaction's accounts
        # @return [Solace::Instruction]
        def self.build(
          amount:,
          decimals:,
          to_index:,
          from_index:,
          mint_index:,
          authority_index:,
          program_index: 3
        )
          Solace::Instruction.new.tap do |ix|
            ix.program_index = program_index
            ix.accounts = [from_index, mint_index, to_index, authority_index]
            ix.data = data(amount, decimals)
          end
        end

        # Instruction data for a TransferChecked instruction.
        #
        # @param amount [Integer] Amount to transfer
        # @param decimals [Integer] Number of decimals for the token
        # @return [Array] 1-byte instruction index + 8-byte amount + 1-byte decimals
        def self.data(amount, decimals)
          INSTRUCTION_INDEX +
            Solace::Utils::Codecs.encode_le_u64(amount).bytes +
            [decimals]
        end
      end
    end
  end
end

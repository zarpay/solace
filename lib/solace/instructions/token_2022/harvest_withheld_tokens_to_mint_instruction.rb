# frozen_string_literal: true

module Solace
  module Instructions
    module Token2022
      # Instruction builder for Token-2022 TransferFeeExtension::HarvestWithheldTokensToMint.
      #
      # Permissionlessly moves withheld transfer fees from token accounts to their
      # mint. A token account holding withheld fees cannot be closed; harvesting
      # first makes the account closeable. No signer is required — anyone may crank.
      #
      # Instruction discriminator: 26 (TransferFeeExtension), sub-instruction: 4
      #
      # Accounts:
      # 1. [writable] Mint
      # 2. [writable] Token account to harvest from (repeatable upstream; one here)
      #
      # @since 0.1.6
      class HarvestWithheldTokensToMintInstruction
        # TransferFeeExtension discriminator followed by HarvestWithheldTokensToMint
        INSTRUCTION_DISCRIMINATOR = [26, 4].freeze

        # Builds a HarvestWithheldTokensToMint instruction.
        #
        # @param mint_index [Integer] Index of the mint
        # @param source_index [Integer] Index of the token account to harvest from
        # @param program_index [Integer] Index of the Token-2022 program
        # @return [Solace::Instruction] The constructed instruction
        def self.build(mint_index:, source_index:, program_index:)
          Solace::Instruction.new.tap do |ix|
            ix.program_index = program_index
            ix.accounts = [mint_index, source_index]
            ix.data = data
          end
        end

        # Builds the data for a HarvestWithheldTokensToMint instruction.
        #
        # The BufferLayout is:
        #   - [Instruction Index (1 byte), Sub-instruction Index (1 byte)]
        #
        # @return [Array] 2-byte instruction path
        def self.data
          INSTRUCTION_DISCRIMINATOR
        end
      end
    end
  end
end

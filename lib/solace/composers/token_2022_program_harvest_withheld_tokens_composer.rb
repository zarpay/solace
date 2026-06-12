# frozen_string_literal: true

module Solace
  module Composers
    # Composer for creating a Token-2022 TransferFeeExtension::HarvestWithheldTokensToMint
    # instruction.
    #
    # Moves withheld transfer fees from a token account back to its mint. An account
    # holding withheld fees cannot be closed, so harvest-then-close is the pattern for
    # reclaiming rent from transfer-fee token accounts. Permissionless: no signer.
    #
    # Required accounts:
    # - **Mint**: the transfer-fee mint (writable, non-signer)
    # - **Source**: token account to harvest from (writable, non-signer)
    #
    # @example Compose and build a harvest instruction
    #   composer = Token2022ProgramHarvestWithheldTokensComposer.new(
    #     mint: mint_address,
    #     source: token_account_address
    #   )
    #
    # @since 0.1.6
    class Token2022ProgramHarvestWithheldTokensComposer < Base
      # Extracts the mint address from the params
      #
      # @return [String] The mint address
      def mint
        params[:mint].to_s
      end

      # Extracts the source token account address from the params
      #
      # @return [String] The source token account address
      def source
        params[:source].to_s
      end

      # @return [String] The Token-2022 program id.
      def token_2022_program
        Constants::TOKEN_2022_PROGRAM_ID.to_s
      end

      # Setup accounts required for the harvest instruction
      # Called automatically during initialization
      #
      # @return [void]
      def setup_accounts
        account_context.add_writable_nonsigner(mint)
        account_context.add_writable_nonsigner(source)
        account_context.add_readonly_nonsigner(token_2022_program)
      end

      # Build instruction with resolved account indices
      #
      # @param account_context [Utils::AccountContext] The account context
      # @return [Solace::Instruction]
      def build_instruction(account_context)
        Instructions::Token2022::HarvestWithheldTokensToMintInstruction.build(
          mint_index: account_context.index_of(mint),
          source_index: account_context.index_of(source),
          program_index: account_context.index_of(token_2022_program)
        )
      end
    end
  end
end

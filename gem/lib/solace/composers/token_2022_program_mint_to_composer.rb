# frozen_string_literal: true

module Solace
  module Composers
    # Composer for creating a MintTo instruction for the Token-2022 Program.
    #
    # This composer builds a MintTo instruction that can be added to a transaction to mint tokens
    # to a specified token account.
    #
    # Required accounts:
    #  - **Mint**: The mint account (writable, non-signer)
    #  - **Destination**: The token account to mint to (writable, non-signer)
    #  - **Mint Authority**: The mint authority account (readonly, signer)
    #
    # @example Build a MintTo instruction
    #   composer = Solace::Composers::Token2022ProgramMintToComposer.new(
    #     mint: mint,
    #     destination: destination,
    #     mint_authority: mint_authority,
    #     amount: 100
    #   )
    #
    # @since 0.1.5
    class Token2022ProgramMintToComposer < Base
      # Extracts the mint address from the params
      #
      # @return [String] The mint address
      def mint
        params[:mint].to_s
      end

      # Extracts the destination address from the params
      #
      # @return [String] The destination address
      def destination
        params[:destination].to_s
      end

      # Extracts the mint authority address from the params
      #
      # @return [String] The mint authority address
      def mint_authority
        params[:mint_authority].to_s
      end

      # @return [String] The Token-2022 program id.
      def token_2022_program
        Constants::TOKEN_2022_PROGRAM_ID.to_s
      end

      # Extracts the amount from the params
      #
      # @return [Integer] The amount
      def amount
        params[:amount].to_i
      end

      # Setup accounts required for MintTo instruction
      # Called automatically during initialization
      #
      # @return [void]
      def setup_accounts
        account_context.add_writable_nonsigner(mint)
        account_context.add_writable_nonsigner(destination)
        account_context.add_readonly_signer(mint_authority)
        account_context.add_readonly_nonsigner(token_2022_program)
      end

      # Build instruction with resolved account indices
      #
      # @param account_context [Utils::AccountContext] The account context
      # @return [Solace::Instruction]
      def build_instruction(account_context)
        Instructions::Token2022::MintToInstruction.build(
          amount:               amount,
          mint_index:           account_context.index_of(mint),
          destination_index:    account_context.index_of(destination),
          mint_authority_index: account_context.index_of(mint_authority),
          program_index:        account_context.index_of(token_2022_program)
        )
      end
    end
  end
end

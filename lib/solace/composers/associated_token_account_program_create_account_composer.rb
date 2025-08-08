# frozen_string_literal: true

module Solace
  module Composers
    # Composer for creating an associated token account program create account instruction
    #
    # This composer resolves and orders the required accounts for a `CreateAssociatedTokenAccount` instruction,
    # sets up their access permissions, and delegates construction to the appropriate
    # instruction builder (`Instructions::AssociatedTokenAccount::CreateAssociatedTokenAccountInstruction`).
    #
    # Required accounts:
    # - **Funder**: the account that will pay for fees and rent.
    # - **Owner**: the account that will own the new ATA.
    # - **ATA**: the address of the new ATA.
    # - **Mint**: the mint address of the token.
    # - **System Program**: the system program id.
    # - **Token Program**: the token program id.
    # - **Associated Token Account Program**: the associated token account program id.
    #
    # @example Compose and build a create account instruction
    #   composer = AssociatedTokenAccountProgramCreateAccountComposer.new(
    #     funder: funder_address,
    #     owner: owner_address,
    #     ata_address: ata_address,
    #     mint: mint_address
    #   )
    #
    # @see Instructions::AssociatedTokenAccount::CreateAssociatedTokenAccountInstruction
    # @since 0.0.7
    class AssociatedTokenAccountProgramCreateAccountComposer < Base
      # Extracts the owner address from the params
      #
      # @return [String] The owner address
      def owner
        params[:owner].is_a?(String) ? params[:owner] : params[:owner].address
      end

      # Extracts the mint address from the params
      #
      # @return [String] The mint address
      def mint
        params[:mint].is_a?(String) ? params[:mint] : params[:mint].address
      end

      # Extracts the ata_address from the params
      #
      # @return [String] The ata_address
      def ata_address
        params[:ata_address].is_a?(String) ? params[:ata_address] : params[:ata_address].address
      end

      # Extracts the funder address from the params
      #
      # @return [String] The funder address
      def funder
        params[:funder].is_a?(String) ? params[:funder] : params[:funder].address
      end

      # Extracts the system program id from the constants
      #
      # @return [String] The system program id
      def system_program_id
        Constants::SYSTEM_PROGRAM_ID
      end

      # Extracts the token program id from the constants
      #
      # @return [String] The token program id
      def token_program_id
        Constants::TOKEN_PROGRAM_ID
      end

      # Extracts the associated token account program id from the constants
      #
      # @return [String] The associated token account program id
      def associated_token_account_program_id
        Constants::ASSOCIATED_TOKEN_ACCOUNT_PROGRAM_ID
      end

      # Setup accounts required for associated token account program create account instruction
      # Called automatically during initialization
      #
      # @return [void]
      def setup_accounts # rubocop:disable Metrics/AbcSize
        account_context.add_writable_signer(funder)
        account_context.add_readonly_nonsigner(owner)
        account_context.add_readonly_nonsigner(ata_address)
        account_context.add_readonly_nonsigner(mint)
        account_context.add_readonly_nonsigner(system_program_id)
        account_context.add_readonly_nonsigner(token_program_id)
        account_context.add_readonly_nonsigner(associated_token_account_program_id)
      end

      # Builds the instruction for the associated token account program create account instruction
      #
      # @param account_context [Utils::AccountContext] The account context
      # @return [Solace::Instruction] The instruction
      def build_instruction(account_context)
        Instructions::AssociatedTokenAccount::CreateAssociatedTokenAccountInstruction.build(
          funder_index: account_context.index_of(funder),
          associated_token_account_index: account_context.index_of(ata_address),
          owner_index: account_context.index_of(owner),
          mint_index: account_context.index_of(mint),
          system_program_index: account_context.index_of(system_program_id),
          token_program_index: account_context.index_of(token_program_id),
          program_index: account_context.index_of(associated_token_account_program_id)
        )
      end
    end
  end
end

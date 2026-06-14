# frozen_string_literal: true

module Solace
  module Composers
    # Composer for creating an associated token account program create account instruction with idempotency
    #
    # This composer resolves and orders the required accounts for a
    # `CreateIdempotentAssociatedTokenAccount` instruction,
    # sets up their access permissions, and delegates construction to the appropriate
    # instruction builder (`Instructions::AssociatedTokenAccount::CreateIdempotentAssociatedTokenAccountInstruction`).
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
    # @see Instructions::AssociatedTokenAccount::CreateAccountInstruction
    # @since 0.1.3
    #
    # rubocop:disable Layout
    class AssociatedTokenAccountProgramCreateIdempotentAccountComposer < AssociatedTokenAccountProgramCreateAccountComposer
      # Builds the instruction for the associated token account program create account instruction
      #
      # @param account_context [Utils::AccountContext] The account context
      # @return [Solace::Instruction] The instruction
      def build_instruction(account_context)
        Instructions::AssociatedTokenAccount::CreateIdempotentAccountInstruction.build(
          funder_index: account_context.index_of(funder),
          owner_index: account_context.index_of(owner),
          mint_index: account_context.index_of(mint),
          associated_token_account_index: account_context.index_of(ata_address),
          system_program_index: account_context.index_of(system_program_id),
          token_program_index: account_context.index_of(token_program_id),
          program_index: account_context.index_of(associated_token_account_program_id)
        )
      end
    end
    # rubocop:enable Layout
  end
end

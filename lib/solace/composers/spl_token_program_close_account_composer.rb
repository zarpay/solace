# frozen_string_literal: true

module Solace
  module Composers
    # Composer for creating a SPL Token Program CloseAccount instruction.
    #
    # This composer resolves and orders the required accounts for a `CloseAccount` instruction,
    # sets up their access permissions, and delegates construction to the appropriate
    # instruction builder.
    #
    # The CloseAccount instruction closes a token account and transfers remaining lamports
    # to a destination account. The account must have a balance of zero tokens.
    #
    # Required accounts:
    # - **Account**: token account to close (writable, non-signer)
    # - **Destination**: account to receive lamports (writable, non-signer)
    # - **Authority**: account authority (non-writable, signer)
    #
    # @example Compose and build a close account instruction
    #   composer = SplTokenProgramCloseAccountComposer.new(
    #     account: token_account_address,
    #     destination: destination_address,
    #     authority: authority_address
    #   )
    #
    # @since 0.1.2
    class SplTokenProgramCloseAccountComposer < Base
      # Extracts the token account address from the params
      #
      # @return [String] The token account address
      def account
        params[:account].to_s
      end

      # Extracts the destination address from the params
      #
      # @return [String] The destination address
      def destination
        params[:destination].to_s
      end

      # Extracts the authority address from the params
      #
      # @return [String] The authority address
      def authority
        params[:authority].to_s
      end

      # @return [String] The token program id (defaults to legacy SPL Token;
      #   pass +params[:token_program_id]+ to target Token-2022).
      def spl_token_program
        (params[:token_program_id] || Constants::TOKEN_PROGRAM_ID).to_s
      end

      # Setup accounts required for close account instruction
      # Called automatically during initialization
      #
      # @return [void]
      def setup_accounts
        account_context.add_writable_nonsigner(account)
        account_context.add_writable_nonsigner(destination)
        account_context.add_readonly_signer(authority)
        account_context.add_readonly_nonsigner(spl_token_program)
      end

      # Build instruction with resolved account indices
      #
      # @param account_context [Utils::AccountContext] The account context
      # @return [Solace::Instruction]
      def build_instruction(account_context)
        Instructions::SplToken::CloseAccountInstruction.build(
          account_index: account_context.index_of(account),
          authority_index: account_context.index_of(authority),
          destination_index: account_context.index_of(destination),
          program_index: account_context.index_of(spl_token_program)
        )
      end
    end
  end
end

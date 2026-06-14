# frozen_string_literal: true

module Solace
  module Composers
    # Composer for creating a Token-2022 Program CloseAccount instruction.
    #
    # The CloseAccount instruction closes a token account and transfers remaining
    # lamports to a destination account. The account must have a balance of zero tokens.
    #
    # Required accounts:
    # - **Account**: token account to close (writable, non-signer)
    # - **Destination**: account to receive lamports (writable, non-signer)
    # - **Authority**: account authority (non-writable, signer)
    #
    # @example Compose and build a close account instruction
    #   composer = Token2022ProgramCloseAccountComposer.new(
    #     account: token_account_address,
    #     destination: destination_address,
    #     authority: authority_address
    #   )
    #
    # @since 0.1.5
    class Token2022ProgramCloseAccountComposer < Base
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

      # @return [String] The Token-2022 program id.
      def token_2022_program
        Constants::TOKEN_2022_PROGRAM_ID.to_s
      end

      # Setup accounts required for close account instruction
      # Called automatically during initialization
      #
      # @return [void]
      def setup_accounts
        account_context.add_writable_nonsigner(account)
        account_context.add_writable_nonsigner(destination)
        account_context.add_readonly_signer(authority)
        account_context.add_readonly_nonsigner(token_2022_program)
      end

      # Build instruction with resolved account indices
      #
      # @param account_context [Utils::AccountContext] The account context
      # @return [Solace::Instruction]
      def build_instruction(account_context)
        Instructions::Token2022::CloseAccountInstruction.build(
          account_index:     account_context.index_of(account),
          authority_index:   account_context.index_of(authority),
          destination_index: account_context.index_of(destination),
          program_index:     account_context.index_of(token_2022_program)
        )
      end
    end
  end
end

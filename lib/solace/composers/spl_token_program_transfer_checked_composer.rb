# frozen_string_literal: true

module Solace
  module Composers
    # Composer for creating a SPL Token Program `TransferChecked` instruction.
    #
    # This composer resolves and orders the required accounts for a `TransferChecked` instruction,
    # sets up their access permissions, and delegates construction to the appropriate
    # instruction builder (`Instructions::SplToken::TransferCheckedInstruction`).
    #
    # It is used for transferring SPL tokens with decimal precision and validation checks.
    #
    # Required accounts:
    # - **From**: source token account (writable, non-signer)
    # - **To**: destination token account (writable, non-signer)
    # - **Mint**: mint address (readonly, non-signer)
    # - **Authority**: token owner (writable, signer)
    # - **Program**: SPL Token program (readonly, non-signer)
    #
    # @example Compose and build a transfer_checked instruction
    #   composer = SplTokenProgramTransferCheckedComposer.new(
    #     from: from_address,
    #     to: to_address,
    #     mint: mint_address,
    #     authority: authority_pubkey,
    #     amount: 1_000_000,
    #     decimals: 6
    #   )
    #
    # @see Instructions::SplToken::TransferCheckedInstruction
    # @since 0.0.3
    class SplTokenProgramTransferCheckedComposer < Base
      # Extracts the to address from the params
      #
      # @return [String] The to address
      def to
        params[:to].is_a?(String) ? params[:to] : params[:to].address
      end

      # Extracts the from address from the params
      #
      # @return [String] The from address
      def from
        params[:from].is_a?(String) ? params[:from] : params[:from].address
      end

      # Extracts the authority address from the params
      #
      # The authority is the owner of the token account
      #
      # @return [String] The authority address
      def authority
        params[:authority].is_a?(String) ? params[:authority] : params[:authority].address
      end

      # Extracts the mint address from the params
      #
      # @return [String] The mint address
      def mint
        params[:mint].is_a?(String) ? params[:mint] : params[:mint].address
      end

      # Returns the spl token program id
      #
      # @return [String] The spl token program id
      def spl_token_program
        Constants::TOKEN_PROGRAM_ID
      end

      # Returns the lamports to transfer
      #
      # @return [Integer] The lamports to transfer
      def amount
        params[:amount]
      end

      # Returns the decimals for the mint of the token
      #
      # @return [Integer] The decimals for the mint
      def decimals
        params[:decimals]
      end

      # Setup accounts required for transfer instruction
      # Called automatically during initialization
      #
      # @return [void]
      def setup_accounts
        account_context.add_writable_signer(authority)
        account_context.add_writable_nonsigner(to)
        account_context.add_writable_nonsigner(from)
        account_context.add_readonly_nonsigner(mint)
        account_context.add_readonly_nonsigner(spl_token_program)
      end

      # Build instruction with resolved account indices
      #
      # @param account_context [Utils::AccountContext] The account context
      # @return [Solace::Instruction]
      def build_instruction(account_context)
        Instructions::SplToken::TransferCheckedInstruction.build(
          amount: amount,
          decimals: decimals,
          to_index: account_context.index_of(to),
          from_index: account_context.index_of(from),
          mint_index: account_context.index_of(mint),
          authority_index: account_context.index_of(authority),
          program_index: account_context.index_of(spl_token_program)
        )
      end
    end
  end
end

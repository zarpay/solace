# frozen_string_literal: true

module Solace
  module Composers
    # Composer for creating a Token-2022 Program Transfer instruction.
    #
    # This composer resolves and orders the required accounts for a `Transfer` instruction,
    # sets up their access permissions, and delegates construction to the appropriate
    # instruction builder (`Instructions::Token2022::TransferInstruction`).
    #
    # Required accounts:
    # - **Owner**: token account owner (writable, signer)
    # - **Source**: source token account (writable, non-signer)
    # - **Destination**: destination token account (writable, non-signer)
    #
    # @example Compose and build a transfer instruction
    #   composer = Token2022ProgramTransferComposer.new(
    #     amount: 1_000_000,
    #     owner: owner_address,
    #     source: source_address,
    #     destination: destination_address,
    #   )
    #
    # @see Instructions::Token2022::TransferInstruction
    # @since 0.1.5
    class Token2022ProgramTransferComposer < Base
      # Extracts the owner address from the params
      #
      # @return [String] The owner address
      def owner
        params[:owner].to_s
      end

      # Extracts the source associated token address from the params
      #
      # @return [String] The source associated token address
      def source
        params[:source].to_s
      end

      # Extracts the destination associated token address from the params
      #
      # @return [String] The destination associated token address
      def destination
        params[:destination].to_s
      end

      # @return [String] The Token-2022 program id.
      def token_2022_program
        Constants::TOKEN_2022_PROGRAM_ID.to_s
      end

      # Returns the lamports to transfer
      #
      # @return [Integer] The lamports to transfer
      def amount
        params[:amount]
      end

      # Setup accounts required for transfer instruction
      # Called automatically during initialization
      #
      # @return [void]
      def setup_accounts
        account_context.add_writable_signer(owner)
        account_context.add_writable_nonsigner(source)
        account_context.add_writable_nonsigner(destination)
        account_context.add_readonly_nonsigner(token_2022_program)
      end

      # Build instruction with resolved account indices
      #
      # @param account_context [Utils::AccountContext] The account context
      # @return [Solace::Instruction]
      def build_instruction(account_context)
        Instructions::Token2022::TransferInstruction.build(
          amount:            amount,
          owner_index:       account_context.index_of(owner),
          source_index:      account_context.index_of(source),
          destination_index: account_context.index_of(destination),
          program_index:     account_context.index_of(token_2022_program)
        )
      end
    end
  end
end

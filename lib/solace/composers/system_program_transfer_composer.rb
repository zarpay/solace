# frozen_string_literal: true

module Solace
  module Composers
    # Composer for creating a system program transfer instruction.
    #
    # This composer resolves and orders the required accounts for a `Transfer` instruction,
    # sets up their access permissions, and delegates construction to the appropriate
    # instruction builder (`Instructions::SystemProgram::TransferInstruction`).
    #
    # It is used for transferring lamports from one account to another.
    #
    # Required accounts:
    # - **From**: source account (writable, signer)
    # - **To**: destination account (writable, non-signer)
    # - **Program**: System program (readonly, non-signer)
    #
    # @example Compose and build a transfer instruction
    #   composer = SystemProgramTransferComposer.new(
    #     from: from_address,
    #     to: to_address,
    #     lamports: 1_000_000
    #   )
    #
    # @see Instructions::SystemProgram::TransferInstruction
    # @since 0.0.3
    class SystemProgramTransferComposer < Base
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

      # Returns the system program id
      #
      # @return [String] The system program id
      def system_program
        Solace::Constants::SYSTEM_PROGRAM_ID
      end

      # Returns the lamports to transfer
      #
      # @return [Integer] The lamports to transfer
      def lamports
        params[:lamports]
      end

      # Setup accounts required for transfer instruction
      # Called automatically during initialization
      #
      # @return [void]
      def setup_accounts
        account_context.add_writable_signer(from)
        account_context.add_writable_nonsigner(to)
        account_context.add_readonly_nonsigner(system_program)
      end

      # Build instruction with resolved account indices
      #
      # @param account_context [Utils::AccountContext] The account context
      # @return [Solace::Instruction]
      def build_instruction(account_context)
        Instructions::SystemProgram::TransferInstruction.build(
          lamports: lamports,
          to_index: account_context.index_of(to),
          from_index: account_context.index_of(from),
          program_index: account_context.index_of(system_program)
        )
      end
    end
  end
end

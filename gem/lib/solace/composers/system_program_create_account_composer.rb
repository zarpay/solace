# frozen_string_literal: true

module Solace
  module Composers
    # Composer for creating an account using the system program.
    #
    # This composer resolves and orders the required accounts for a `CreateAccount` instruction,
    # sets up their access permissions, and delegates construction to the appropriate
    # instruction builder (`Instructions::SystemProgram::CreateAccountInstruction`).
    #
    # It is used for creating new accounts on the Solana blockchain.
    #
    # Required accounts:
    # - **From**: funding account (writable, signer)
    # - **Owner**: owner program id (readonly, non-signer)
    # - **New Account**: new account to create (writable, signer)
    #
    # @example Compose and build a create account instruction
    #   composer = SystemProgramCreateAccountComposer.new(
    #     from: payer_address,
    #     new_account: new_account_address,
    #     owner: owner_address,
    #     lamports: 1000,
    #     space: 1024
    #   )
    #
    # @see Instructions::SystemProgram::CreateAccountInstruction
    # @since 0.1.0
    class SystemProgramCreateAccountComposer < Base
      # Extracts the to address from the params
      #
      # @return [String] The from address
      def from
        params[:from].to_s
      end

      # Extracts the new account address from the params
      #
      # @return [String] The new account address
      def new_account
        params[:new_account].to_s
      end

      # Returns the system program id
      #
      # @return [String] The system program id
      def system_program
        Solace::Constants::SYSTEM_PROGRAM_ID.to_s
      end

      # Extracts the owner address from the params
      #
      # @return [String] The owner address
      def owner
        params[:owner].to_s
      end

      # Returns the lamports to transfer
      #
      # @return [Integer] The lamports to transfer
      def lamports
        params[:lamports]
      end

      # Returns the space to allocate
      #
      # @return [Integer] The space to allocate
      def space
        params[:space]
      end

      # Setup accounts required for create account instruction
      # Called automatically during initialization
      #
      # @return [void]
      def setup_accounts
        account_context.add_writable_signer(from)
        account_context.add_writable_signer(new_account)
        account_context.add_readonly_nonsigner(system_program)
      end

      # Build instruction with resolved account indices
      #
      # @param account_context [Utils::AccountContext] The account context
      # @return [Solace::Instruction]
      def build_instruction(account_context)
        Solace::Instructions::SystemProgram::CreateAccountInstruction.build(
          space:                space,
          lamports:             lamports,
          owner:                owner,
          from_index:           account_context.index_of(from),
          new_account_index:    account_context.index_of(new_account),
          system_program_index: account_context.index_of(system_program)
        )
      end
    end
  end
end

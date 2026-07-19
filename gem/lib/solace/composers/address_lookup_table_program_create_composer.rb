# frozen_string_literal: true

module Solace
  module Composers
    # Composer for creating an address lookup table.
    #
    # Resolves and orders the accounts for a `CreateLookupTable` instruction and
    # delegates construction to
    # `Instructions::AddressLookupTableProgram::CreateLookupTableInstruction`.
    #
    # The table address is a program-derived address of `[authority, recent_slot]`;
    # derive it (and its bump) with {Solace::Utils::PDA} and pass both in.
    #
    # Required accounts:
    # - **Table**: the uninitialized table account (writable, non-signer)
    # - **Authority**: controls the table (readonly, signer)
    # - **Payer**: funds the table's rent (writable, signer)
    # - **System program** (readonly, non-signer)
    #
    # @example
    #   composer = AddressLookupTableProgramCreateComposer.new(
    #     table:       table_address,
    #     authority:   authority,
    #     payer:       payer,
    #     recent_slot: recent_slot,
    #     bump:        bump
    #   )
    #
    # @see Instructions::AddressLookupTableProgram::CreateLookupTableInstruction
    # @since 0.1.8
    class AddressLookupTableProgramCreateComposer < Base
      # @return [String] The table's on-chain address
      def table
        params[:table].to_s
      end

      # @return [String] The table authority
      def authority
        params[:authority].to_s
      end

      # @return [String] The rent payer
      def payer
        params[:payer].to_s
      end

      # @return [String] The system program id
      def system_program
        Solace::Constants::SYSTEM_PROGRAM_ID.to_s
      end

      # @return [String] The address lookup table program id
      def lookup_table_program
        Solace::Constants::ADDRESS_LOOKUP_TABLE_PROGRAM_ID.to_s
      end

      # @return [Integer] The slot used to derive the table address
      def recent_slot
        params[:recent_slot]
      end

      # @return [Integer] The bump seed for the table's program-derived address
      def bump
        params[:bump]
      end

      # Setup accounts required for the create lookup table instruction
      #
      # @return [void]
      def setup_accounts
        account_context.add_writable_nonsigner(table)
        account_context.add_readonly_signer(authority)
        account_context.add_writable_signer(payer)
        account_context.add_readonly_nonsigner(system_program)
        account_context.add_readonly_nonsigner(lookup_table_program)
      end

      # Build instruction with resolved account indices
      #
      # @param account_context [Utils::AccountContext] The account context
      # @return [Solace::Instruction]
      def build_instruction(account_context)
        Solace::Instructions::AddressLookupTableProgram::CreateLookupTableInstruction.build(
          recent_slot:          recent_slot,
          bump:                 bump,
          program_index:        account_context.index_of(lookup_table_program),
          table_index:          account_context.index_of(table),
          authority_index:      account_context.index_of(authority),
          payer_index:          account_context.index_of(payer),
          system_program_index: account_context.index_of(system_program)
        )
      end
    end
  end
end

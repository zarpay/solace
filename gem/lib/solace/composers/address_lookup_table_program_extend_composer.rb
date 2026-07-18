# frozen_string_literal: true

module Solace
  module Composers
    # Composer for extending an address lookup table with new addresses.
    #
    # Resolves and orders the accounts for an `ExtendLookupTable` instruction and
    # delegates construction to
    # `Instructions::AddressLookupTableProgram::ExtendLookupTableInstruction`.
    #
    # Addresses appended here become usable one slot after the extend lands.
    #
    # Required accounts:
    # - **Table**: the table account being extended (writable, non-signer)
    # - **Authority**: controls the table (readonly, signer)
    # - **Payer**: funds any additional rent (writable, signer)
    # - **System program** (readonly, non-signer)
    #
    # @example
    #   composer = AddressLookupTableProgramExtendComposer.new(
    #     table:     table_address,
    #     authority: authority,
    #     payer:     payer,
    #     addresses: [recipient1, recipient2]
    #   )
    #
    # @see Instructions::AddressLookupTableProgram::ExtendLookupTableInstruction
    # @since 0.1.7
    class AddressLookupTableProgramExtendComposer < Base
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

      # @return [Array<String>] The addresses to append to the table
      def addresses
        params[:addresses].map(&:to_s)
      end

      # Setup accounts required for the extend lookup table instruction
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
        Solace::Instructions::AddressLookupTableProgram::ExtendLookupTableInstruction.build(
          addresses:            addresses,
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

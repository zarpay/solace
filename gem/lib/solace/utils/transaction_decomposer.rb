# frozen_string_literal: true

require_relative 'compute_budget'
require_relative '../composers/instruction_composer'
require_relative '../instructions/compute_budget/set_compute_unit_limit_instruction'
require_relative '../instructions/compute_budget/set_compute_unit_price_instruction'

module Solace
  module Utils
    # Reads a compiled message back into the parts a composer is built from
    #
    # Answers the instructions as {Composers::InstructionComposer}s carrying the
    # accounts and flags the message header gave them, the compute budget the
    # message carried, the lookup tables it references read from chain, its fee
    # payer and its blockhash. Every answer is derived once and memoised.
    #
    # The Solana facts it applies:
    #
    # - Static keys take their flags from the header ordering: signers first,
    #   writable before read-only, then non-signers the same way.
    # - A v0 message's instruction indexes address the combined space: the
    #   static keys, then every table's writable entries in table order, then
    #   every table's read-only entries. A loaded address never signs and is
    #   writable by the segment it sits in.
    # - A table that does not exist on chain is an error, not an empty list.
    #
    # @see Solace::TransactionComposer.from
    # @since 0.1.9
    class TransactionDecomposer
      # The ComputeBudget program id
      COMPUTE_BUDGET_PROGRAM_ID = Constants::COMPUTE_BUDGET_PROGRAM_ID
      private_constant :COMPUTE_BUDGET_PROGRAM_ID

      # The discriminators of the two directives the budget setting holds
      LIMIT_INDEX = Instructions::ComputeBudget::SetComputeUnitLimitInstruction::INSTRUCTION_INDEX.first
      PRICE_INDEX = Instructions::ComputeBudget::SetComputeUnitPriceInstruction::INSTRUCTION_INDEX.first
      private_constant :LIMIT_INDEX, :PRICE_INDEX

      # @!attribute message
      #   The message being taken apart
      attr_reader :message

      # @!attribute connection
      #   The connection the lookup tables are read through
      attr_reader :connection

      # @param transaction [Solace::Transaction, Solace::Message, String] The transaction
      #   to take apart — the transaction, its message, or its base64
      # @param connection [Solace::Connection] The connection to read lookup tables through
      def initialize(transaction, connection:)
        @message    = message_of(transaction)
        @connection = connection
      end

      # The fee payer: the first static key
      #
      # @return [String] The fee payer pubkey
      def fee_payer
        message.accounts.first
      end

      # The blockhash the message was composed against
      #
      # @return [String] The blockhash (base58)
      def blockhash
        message.recent_blockhash
      end

      # The lookup tables the message references, read from chain once each
      #
      # @return [Array<Accounts::AddressLookupTable>] The tables, in message order
      def lookup_tables
        @lookup_tables ||= references.map(&:account).uniq.map { |account| table_for(account) }
      end

      # The combined account space the instruction indexes address
      #
      # @return [Array<String>] Static keys, then loaded writable, then loaded readonly pubkeys
      def accounts
        @accounts ||= message.accounts + loaded(:writable_indexes) + loaded(:readonly_indexes)
      end

      # The account at an index of the combined space, with its flags
      #
      # @param index [Integer] The index into {#accounts}
      # @return [Hash] `{ pubkey:, signer:, writable: }`
      def account_meta(index)
        { pubkey: accounts.fetch(index), **flags_for(index) }
      end

      # The static accounts declared in message order with their flags
      #
      # Seeding a composer's context with this keeps the original account
      # order when the message is composed again.
      #
      # @return [AccountContext] A context holding the static keys
      def account_context
        @account_context ||= Composers::InstructionComposer.new(
          program_id: fee_payer, accounts: message.accounts.each_index.map { |index| account_meta(index) }, data: []
        ).account_context
      end

      # The message's instructions as composers, the budget directives left out
      #
      # @return [Array<Composers::InstructionComposer>] One composer per instruction, in order
      def instruction_composers
        @instruction_composers ||= message.instructions.reject { |instruction| budget?(instruction) }
                                          .map { |instruction| composer_for(instruction) }
      end

      # The compute budget the message carried
      #
      # @return [ComputeBudget] The budget, unset when the message carried none
      def compute_budget
        @compute_budget ||= ComputeBudget.new(
          units:          budget_value(LIMIT_INDEX)&.then { |bytes| bytes.pack('C*').unpack1('L<') },
          micro_lamports: budget_value(PRICE_INDEX)&.then { |bytes| bytes.pack('C*').unpack1('Q<') }
        )
      end

      # Fill a composer with everything read from the message
      #
      # The static keys seed the context in message order so the composer
      # composes the same account order again; then the fee payer, the
      # instructions, the tables and the budget are set through its own API.
      #
      # @param composer [Solace::TransactionComposer] A fresh composer
      # @return [Solace::TransactionComposer] The same composer, filled
      def recover_into(composer)
        composer.context.merge_from(account_context)
        composer.set_fee_payer(fee_payer)
        instruction_composers.each { |instruction| composer.add_instruction(instruction) }
        register_tables(composer)
        apply_budget(composer)
      end

      private

      # The message of a transaction given in any of its representations
      #
      # @param transaction [Solace::Transaction, Solace::Message, String]
      # @return [Solace::Message]
      def message_of(transaction)
        case transaction
        when Solace::Message then transaction
        when String then Solace::Transaction.from(transaction).message
        else transaction.message
        end
      end

      # Register every table the message references on the composer
      #
      # @param composer [Solace::TransactionComposer]
      # @return [void]
      def register_tables(composer)
        lookup_tables.each do |table|
          composer.add_address_lookup_table(account: table.account, addresses: table.addresses)
        end
      end

      # Set the recovered budget on the composer, when the message carried one
      #
      # @param composer [Solace::TransactionComposer]
      # @return [Solace::TransactionComposer] The composer
      def apply_budget(composer)
        return composer unless compute_budget.set?

        composer.set_compute_budget(units: compute_budget.units, micro_lamports: compute_budget.micro_lamports)
      end

      # The table references the message carries
      #
      # @return [Array<Solace::AddressLookupTable>]
      def references
        Array(message.address_lookup_tables)
      end

      # The on-chain table for an account, fetched once
      #
      # @param account [String] The table account
      # @return [Accounts::AddressLookupTable]
      def table_for(account)
        @tables            ||= {}
        @tables[account]   ||= Accounts::AddressLookupTable.fetch(account, connection: connection)
      end

      # The pubkeys one segment loads, across every table in table order
      #
      # @param kind [Symbol] :writable_indexes or :readonly_indexes
      # @return [Array<String>]
      def loaded(kind)
        references.flat_map do |reference|
          addresses = table_for(reference.account).addresses
          reference.public_send(kind).map { |index| addresses.fetch(index) }
        end
      end

      # The signer and writable flags of the account at an index
      #
      # @param index [Integer] The index into the combined space
      # @return [Hash] `{ signer:, writable: }`
      def flags_for(index)
        static_count = message.accounts.size
        return loaded_flags_for(index - static_count) if index >= static_count

        signers, readonly_signed, readonly_unsigned = message.header

        if index < signers
          { signer: true, writable: index < signers - readonly_signed }
        else
          { signer: false, writable: index < static_count - readonly_unsigned }
        end
      end

      # The flags of a loaded account: never a signer, writable by its segment
      #
      # @param offset [Integer] The index past the static keys
      # @return [Hash] `{ signer:, writable: }`
      def loaded_flags_for(offset)
        { signer: false, writable: offset < loaded(:writable_indexes).size }
      end

      # A composer carrying an instruction's program, accounts and data
      #
      # @param instruction [Solace::Instruction]
      # @return [Composers::InstructionComposer]
      def composer_for(instruction)
        Composers::InstructionComposer.new(
          program_id: accounts.fetch(instruction.program_index),
          accounts:   instruction.accounts.map { |index| account_meta(index) },
          data:       instruction.data
        )
      end

      # Whether an instruction is a limit or price directive the budget setting holds
      #
      # @param instruction [Solace::Instruction]
      # @return [Boolean]
      def budget?(instruction)
        accounts.fetch(instruction.program_index) == COMPUTE_BUDGET_PROGRAM_ID &&
          [LIMIT_INDEX, PRICE_INDEX].include?(instruction.data.first)
      end

      # The value bytes of the first budget directive with the given discriminator
      #
      # @param discriminator [Integer] The directive's first data byte
      # @return [Array<Integer>, nil] The bytes after the discriminator, or nil when absent
      def budget_value(discriminator)
        message.instructions.find { |instruction| budget?(instruction) && instruction.data.first == discriminator }
               &.data&.drop(1)
      end
    end
  end
end

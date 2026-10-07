# frozen_string_literal: true

require_relative 'composers/base'
require_relative 'composers/opaque_instruction_composer'
require_relative 'instructions/compute_budget/set_compute_unit_limit_instruction'
require_relative 'instructions/compute_budget/set_compute_unit_price_instruction'

module Solace
  # Takes a transaction apart into the composer that composes it again
  #
  # The reverse of {TransactionComposer}: given a transaction (or its base64),
  # answers a {TransactionComposer} holding one
  # {Composers::OpaqueInstructionComposer} per instruction, in order, each
  # carrying the program it invokes, its accounts with the signer and writable
  # flags the message header gave them, and its data untouched. The lookup
  # tables a v0 message references are read from chain once and registered, and
  # the version is kept, so the composer composes as v0 again (with or without
  # tables); a `SetComputeUnitLimit` or
  # `SetComputeUnitPrice` the transaction carried becomes the composer's
  # {TransactionComposer#compute_budget}; and the blockhash it was composed
  # against is set as the composer's {TransactionComposer#blockhash}.
  #
  # The Solana facts applied:
  #
  # - Static keys take their flags from the header ordering: signers first,
  #   writable before read-only, then non-signers the same way.
  # - A v0 message's instruction indexes address the combined space: the
  #   static keys, then every table's writable entries in table order, then
  #   every table's read-only entries. A loaded address never signs and is
  #   writable by the segment it sits in.
  # - A table that does not exist on chain is an error, not an empty list.
  #
  # For a transaction a {TransactionComposer} built, the composer answered here
  # composes the same bytes again.
  #
  # @example
  #   composer = Solace::TransactionDecomposer.new(connection: connection).decompose_transaction(transaction)
  #   composer.instruction_composers # => the recovered instructions
  #   composer.compose_transaction   # => the transaction again
  #
  # @see Solace::TransactionComposer
  # @since 0.1.9
  class TransactionDecomposer
    # The discriminators of the two directives the budget setting holds
    LIMIT_INDEX = Instructions::ComputeBudget::SetComputeUnitLimitInstruction::INSTRUCTION_INDEX.first
    PRICE_INDEX = Instructions::ComputeBudget::SetComputeUnitPriceInstruction::INSTRUCTION_INDEX.first
    private_constant :LIMIT_INDEX, :PRICE_INDEX

    # What one call reads off a message: the message, the tables it references
    # (by account, read from chain), the combined account space in index
    # order, and a context declaring every account's role
    Reading = Struct.new(:message, :tables, :accounts, :roles, keyword_init: true)
    private_constant :Reading

    # @!attribute connection
    #   The connection lookup tables are read through
    attr_reader :connection

    # @param connection [Solace::Connection] The connection to read lookup tables through
    def initialize(connection:)
      @connection = connection
    end

    # Take a transaction apart
    #
    # @param transaction [Solace::Transaction, String] The transaction, or its base64
    # @return [Solace::TransactionComposer] A composer that composes it again
    # @raise [Solace::Errors::AddressLookupTableNotFound] When a referenced table is not on chain
    def decompose_transaction(transaction)
      message  = message_of(transaction)
      reading  = read(message)
      composer = TransactionComposer.new(connection: connection)
                                    .set_version(message.version)
                                    .set_blockhash(message.recent_blockhash)

      seed(composer, reading)
      fill(composer, reading)
    end

    private

    # Read a message: its tables from chain, its combined account space, and
    # the role of every account in it
    #
    # @param message [Solace::Message]
    # @return [Reading]
    def read(message)
      tables   = fetch_tables(message)
      writable = loaded(message, tables, :writable_indexes)
      readonly = loaded(message, tables, :readonly_indexes)
      roles    = Utils::AccountContext.new

      declare_static(roles, message)
      writable.each { |pubkey| roles.merge_account(pubkey, signer: false, writable: true) }
      readonly.each { |pubkey| roles.merge_account(pubkey, signer: false, writable: false) }

      accounts = message.accounts + writable + readonly

      Reading.new(message: message, tables: tables, accounts: accounts, roles: roles)
    end

    # Declare the static keys with the roles their header positions give them:
    # signers first, writable before read-only, then non-signers the same way
    #
    # @param roles [Utils::AccountContext]
    # @param message [Solace::Message]
    # @return [void]
    def declare_static(roles, message)
      signers, readonly_signed, readonly_unsigned = message.header

      message.accounts.each_with_index do |pubkey, index|
        is_signer     = index < signers
        readonly_from = is_signer ? signers - readonly_signed : message.accounts.size - readonly_unsigned
        is_writable   = index < readonly_from

        roles.merge_account(pubkey, signer: is_signer, writable: is_writable)
      end
    end

    # Seed the composer's accounts in message order and set the fee payer, so
    # it composes the same account order again
    #
    # @param composer [Solace::TransactionComposer]
    # @param reading [Reading]
    # @return [void]
    def seed(composer, reading)
      composer.context.merge_from(reading.roles)
      composer.set_fee_payer(reading.message.accounts.first)
    end

    # Add the instructions, register the tables, and set the budget
    #
    # @param composer [Solace::TransactionComposer]
    # @param reading [Reading]
    # @return [Solace::TransactionComposer] The composer
    def fill(composer, reading)
      instruction_composers(reading).each { |instruction| composer.add_instruction(instruction) }

      reading.tables.each_value do |table|
        composer.add_address_lookup_table(account: table.account, addresses: table.addresses)
      end

      budget = compute_budget(reading)
      composer.set_compute_budget(units: budget.units, micro_lamports: budget.micro_lamports) if budget.set?

      composer
    end

    # The message of a transaction given as the object or its base64
    #
    # @param transaction [Solace::Transaction, String]
    # @return [Solace::Message]
    def message_of(transaction)
      transaction = Solace::Transaction.from(transaction) if transaction.is_a?(String)
      transaction.message
    end

    # The tables the message references, read from chain once each, in message order
    #
    # @param message [Solace::Message]
    # @return [Hash{String => Accounts::AddressLookupTable}] Keyed by table account
    def fetch_tables(message)
      references = Array(message.address_lookup_tables)
      accounts   = references.map(&:account).uniq

      accounts.to_h do |account|
        table = Accounts::AddressLookupTable.fetch(account, connection: connection)
        raise Errors::AddressLookupTableNotFound, account unless table

        [account, table]
      end
    end

    # The pubkeys one segment loads, across every table in table order
    #
    # @param message [Solace::Message]
    # @param tables [Hash{String => Accounts::AddressLookupTable}]
    # @param kind [Symbol] :writable_indexes or :readonly_indexes
    # @return [Array<String>]
    def loaded(message, tables, kind)
      references = Array(message.address_lookup_tables)

      references.flat_map do |reference|
        addresses = tables.fetch(reference.account).addresses
        indexes   = kind == :writable_indexes ? reference.writable_indexes : reference.readonly_indexes

        indexes.map { |index| addresses.fetch(index) }
      end
    end

    # The message's instructions as composers, the budget directives left out
    #
    # @param reading [Reading]
    # @return [Array<Composers::OpaqueInstructionComposer>]
    def instruction_composers(reading)
      lifted = reading.message.instructions.reject { |instruction| budget?(instruction, reading) }

      lifted.map do |instruction|
        program_id = reading.accounts.fetch(instruction.program_index)
        accounts   = instruction.accounts.map { |index| reading.accounts.fetch(index) }

        Composers::OpaqueInstructionComposer.new(
          program_id: program_id,
          accounts:   accounts,
          data:       instruction.data,
          roles:      reading.roles
        )
      end
    end

    # Whether an instruction is a limit or price directive the budget setting holds
    #
    # @param instruction [Solace::Instruction]
    # @param reading [Reading]
    # @return [Boolean]
    def budget?(instruction, reading)
      program_id    = reading.accounts.fetch(instruction.program_index)
      discriminator = instruction.data.first

      program_id == Constants::COMPUTE_BUDGET_PROGRAM_ID && [LIMIT_INDEX, PRICE_INDEX].include?(discriminator)
    end

    # The budget the message carried, decoded from its limit and price directives
    #
    # @param reading [Reading]
    # @return [Utils::ComputeBudget] Unset when the message carried neither
    def compute_budget(reading)
      directives = reading.message.instructions.select { |instruction| budget?(instruction, reading) }

      Utils::ComputeBudget.new(
        units:          decode(directives, LIMIT_INDEX, 'L<'),
        micro_lamports: decode(directives, PRICE_INDEX, 'Q<')
      )
    end

    # The value of the first directive with the given discriminator, or nil
    #
    # @param directives [Array<Solace::Instruction>] The budget directives
    # @param discriminator [Integer] The directive's first data byte
    # @param format [String] The pack format of the value that follows it
    # @return [Integer, nil]
    def decode(directives, discriminator, format)
      directive = directives.find { |instruction| instruction.data.first == discriminator }
      return unless directive

      value_bytes = directive.data.drop(1)
      value_bytes.pack('C*').unpack1(format)
    end
  end
end

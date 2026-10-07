# frozen_string_literal: true

require_relative 'composers/base'
require_relative 'composers/opaque_instruction_composer'
require_relative 'instructions/compute_budget/set_compute_unit_limit_instruction'
require_relative 'instructions/compute_budget/set_compute_unit_price_instruction'

module Solace
  # Takes a transaction apart into the composer that composes it again
  #
  # The reverse of {TransactionComposer}: given a transaction (or its message,
  # or its base64), answers a {TransactionComposer} holding one
  # {Composers::OpaqueInstructionComposer} per instruction, in order, each
  # carrying the program it invokes, its accounts with the signer and writable
  # flags the message header gave them, and its data untouched. The lookup
  # tables a v0 message references are read from chain once and registered so
  # the composer composes as v0 again; a `SetComputeUnitLimit` or
  # `SetComputeUnitPrice` the transaction carried becomes the composer's
  # {TransactionComposer#compute_budget}; and the blockhash it was composed
  # against becomes the composer's {TransactionComposer#blockhash}.
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
    # (by account, read from chain), and every account of the combined space
    # with its flags, in index order
    Reading = Struct.new(:message, :tables, :metas, keyword_init: true)
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
    # @param transaction [Solace::Transaction, Solace::Message, String] The transaction,
    #   its message, or its base64
    # @return [Solace::TransactionComposer] A composer that composes it again
    # @raise [Solace::Errors::AddressLookupTableNotFound] When a referenced table is not on chain
    def decompose_transaction(transaction)
      reading  = read(message_of(transaction))
      composer = TransactionComposer.new(connection: connection, blockhash: reading.message.recent_blockhash)

      seed(composer, reading)
      fill(composer, reading)
    end

    private

    # Read a message: its tables from chain, and every account with its flags
    #
    # @param message [Solace::Message]
    # @return [Reading]
    def read(message)
      tables = fetch_tables(message)

      Reading.new(message: message, tables: tables, metas: account_metas(message, tables))
    end

    # Declare the static keys in message order and the fee payer, so the
    # composer composes the same account order again
    #
    # @param composer [Solace::TransactionComposer]
    # @param reading [Reading]
    # @return [void]
    def seed(composer, reading)
      static = reading.metas.first(reading.message.accounts.size)
      seeded = Composers::OpaqueInstructionComposer.new(program_id: static.first[:pubkey], accounts: static, data: [])

      composer.context.merge_from(seeded.account_context)
      composer.set_fee_payer(static.first[:pubkey])
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
      budget.set? ? composer.set_compute_budget(units: budget.units, micro_lamports: budget.micro_lamports) : composer
    end

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

    # The tables the message references, read from chain once each, in message order
    #
    # @param message [Solace::Message]
    # @return [Hash{String => Accounts::AddressLookupTable}] Keyed by table account
    def fetch_tables(message)
      Array(message.address_lookup_tables).map(&:account).uniq.to_h do |account|
        table = Accounts::AddressLookupTable.fetch(account, connection: connection)
        raise Errors::AddressLookupTableNotFound, account unless table

        [account, table]
      end
    end

    # Every account of the combined space with its flags, in index order
    #
    # @param message [Solace::Message]
    # @param tables [Hash{String => Accounts::AddressLookupTable}]
    # @return [Array<Hash>] `{ pubkey:, signer:, writable: }` per index
    def account_metas(message, tables)
      static   = message.accounts.each_with_index.map do |pubkey, index|
        { pubkey: pubkey, **static_flags(message, index) }
      end
      writable = loaded_metas(message, tables, :writable_indexes, writable: true)
      readonly = loaded_metas(message, tables, :readonly_indexes, writable: false)

      static + writable + readonly
    end

    # The flags of a static key, from its position in the header ordering
    #
    # @param message [Solace::Message]
    # @param index [Integer] The index into the static keys
    # @return [Hash] `{ signer:, writable: }`
    def static_flags(message, index)
      signers, readonly_signed, readonly_unsigned = message.header

      if index < signers
        { signer: true, writable: index < signers - readonly_signed }
      else
        { signer: false, writable: index < message.accounts.size - readonly_unsigned }
      end
    end

    # The metas of one loaded segment: never a signer, writable by the segment
    #
    # @param message [Solace::Message]
    # @param tables [Hash{String => Accounts::AddressLookupTable}]
    # @param kind [Symbol] :writable_indexes or :readonly_indexes
    # @param writable [Boolean] The segment's writability
    # @return [Array<Hash>]
    def loaded_metas(message, tables, kind, writable:)
      loaded(message, tables, kind).map { |pubkey| { pubkey: pubkey, signer: false, writable: writable } }
    end

    # The pubkeys one segment loads, across every table in table order
    #
    # @param message [Solace::Message]
    # @param tables [Hash{String => Accounts::AddressLookupTable}]
    # @param kind [Symbol] :writable_indexes or :readonly_indexes
    # @return [Array<String>]
    def loaded(message, tables, kind)
      Array(message.address_lookup_tables).flat_map do |reference|
        addresses = tables.fetch(reference.account).addresses
        reference.public_send(kind).map { |index| addresses.fetch(index) }
      end
    end

    # The message's instructions as composers, the budget directives left out
    #
    # @param reading [Reading]
    # @return [Array<Composers::OpaqueInstructionComposer>]
    def instruction_composers(reading)
      metas = reading.metas

      reading.message.instructions.reject { |instruction| budget?(instruction, metas) }.map do |instruction|
        Composers::OpaqueInstructionComposer.new(
          program_id: metas.fetch(instruction.program_index)[:pubkey],
          accounts:   instruction.accounts.map { |index| metas.fetch(index) },
          data:       instruction.data
        )
      end
    end

    # Whether an instruction is a limit or price directive the budget setting holds
    #
    # @param instruction [Solace::Instruction]
    # @param metas [Array<Hash>] The combined account metas
    # @return [Boolean]
    def budget?(instruction, metas)
      metas.fetch(instruction.program_index)[:pubkey] == Constants::COMPUTE_BUDGET_PROGRAM_ID &&
        [LIMIT_INDEX, PRICE_INDEX].include?(instruction.data.first)
    end

    # The budget the message carried, decoded from its limit and price directives
    #
    # @param reading [Reading]
    # @return [Utils::ComputeBudget] Unset when the message carried neither
    def compute_budget(reading)
      directives = reading.message.instructions.select { |instruction| budget?(instruction, reading.metas) }

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
      directive && directive.data.drop(1).pack('C*').unpack1(format)
    end
  end
end

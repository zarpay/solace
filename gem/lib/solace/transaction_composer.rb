# frozen_string_literal: true

# lib/solace/transaction_composer.rb
module Solace
  # Composes transactions with automatic account management and instruction building.
  #
  # This class allows you to add multiple instruction composers, manage account contexts,
  # and build a complete transaction in a flexible way. It is a high-level abstraction over
  # the process of creating Solana transactions, making it easier to work with complex
  # transaction scenarios.
  #
  # For most use cases, you will create an instance of this class, add instruction composers,
  # and then call the `compose_transaction` method to build the final transaction. That said,
  # all of the individual pieces are also accessible for more advanced use cases.
  #
  # @example
  #   # Initialize a transaction composer
  #   composer = Solace::TransactionComposer.new(connection: connection)
  #
  #   # Add an instruction composer
  #   composer.add_instruction(
  #     Solace::Composers::SystemProgramTransferComposer.new(
  #       to: 'pubkey1',
  #       from: 'pubkey2',
  #       lamports: 100
  #     )
  #   )
  #
  #   # Add another instruction composer
  #   composer.add_instruction(
  #     Solace::Composers::SplTokenProgramTransferCheckedComposer.new(
  #       from: 'pubkey4',
  #       to: 'pubkey5',
  #       mint: 'pubkey6',
  #       authority: 'pubkey7',
  #       amount: 1_000_000,
  #       decimals: 6
  #     )
  #   )
  #
  #   # Set the fee payer
  #   composer.set_fee_payer('pubkey8')
  #
  #   # Compose the transaction
  #   tx = composer.compose_transaction
  #
  #   # Sign the transaction with all required signers
  #   tx.sign(*required_signers)
  #
  # @example
  #   # Chaining methods will return the composer itself for further modifications. The add, prepend,
  #   # and insert methods allow for dynamic insertion of instruction composers at required positions.
  #   transaction_composer = Solace::TransactionComposer
  #     .new(connection: connection)
  #     .add_instruction(instruction_composer_1)
  #     .prepend_instruction(instruction_composer_2)
  #     .insert_instruction(1, instruction_composer_3)
  #     .set_fee_payer(fee_payer_pubkey)
  #     .compose_transaction
  #
  # @see Solace::Composers::Base
  # @since 0.0.6
  class TransactionComposer
    # @!attribute connection
    #   The connection to the Solana cluster
    attr_reader :connection

    # @!attribute context
    #   The account context
    attr_reader :context

    # @!attribute instruction_composers
    #   The instruction composers
    attr_reader :instruction_composers

    # @!attribute lookup_tables
    #   The lookup table context
    attr_reader :lookup_tables

    # Initialize the composer
    #
    # @param connection [Solace::Connection] The connection to the Solana cluster
    def initialize(connection:)
      @connection            = connection
      @instruction_composers = []
      @context               = Utils::AccountContext.new
      @lookup_tables         = Utils::LookupTableContext.new
    end

    # Add an instruction composer to the transaction
    #
    # @param composer [Composers::Base] The instruction composer
    # @return [TransactionComposer] Self for chaining
    def add_instruction(composer)
      merge_accounts(composer.account_context)
      instruction_composers << composer
      self
    end

    # Prepend an instruction composer to the transaction
    #
    # @param composer [Composers::Base] The instruction composer
    # @return [TransactionComposer] Self for chaining
    #
    # @since 0.1.0
    def prepend_instruction(composer)
      merge_accounts(composer.account_context)
      instruction_composers.unshift(composer)
      self
    end

    # Insert an instruction composer at a specific index
    #
    # @param index [Integer] The index to insert at
    # @param composer [Composers::Base] The instruction composer
    # @return [TransactionComposer] Self for chaining
    #
    # @since 0.1.0
    def insert_instruction(index, composer)
      merge_accounts(composer.account_context)
      instruction_composers.insert(index, composer)
      self
    end

    # Merge another TransactionComposer into this one
    #
    # @param other [TransactionComposer] The other composer to merge
    # @param placement [Symbol] :add to append, :prepend to prepend
    # @param index [Integer, nil] The index to insert at if placement is :insert
    # @return [TransactionComposer] Self for chaining
    #
    # @since 0.1.0
    def merge(other, placement: :add, index: nil)
      merge_accounts(other.context)

      case placement
      when :add
        # Appends the other's instruction composers to this one's list
        instruction_composers.concat(other.instruction_composers)
      when :insert
        # Inserts the other's instruction composers at the specified index
        instruction_composers.insert(index, *other.instruction_composers)
      when :prepend
        # Prepends the other's instruction composers to this one's list
        instruction_composers.unshift(*other.instruction_composers)
      else
        raise ArgumentError, "Invalid placement option: #{placement}"
      end

      self
    end

    # Set the fee payer for the transaction
    #
    # @param pubkey [#to_s, PublicKey] The fee payer pubkey
    # @return [TransactionComposer] Self for chaining
    def set_fee_payer(pubkey)
      context.set_fee_payer(pubkey.to_s)
      self
    end

    # Make an address lookup table available to the transaction
    #
    # When at least one lookup table is added, `compose_transaction` emits a v0
    # message: every compiled account that can be loaded through a table (a
    # non-signer that is not the fee payer and not a program id of any
    # instruction) is referenced by table index instead of occupying a static
    # account slot.
    #
    # @example
    #   composer.add_lookup_table(
    #     account:   table_address,
    #     addresses: on_chain_table_addresses
    #   )
    #
    # @param account [#to_s, PublicKey] The lookup table's on-chain address
    # @param addresses [Array<#to_s>] The full, ordered list of addresses stored in the table
    # @return [TransactionComposer] Self for chaining
    #
    # @since 0.1.8
    def add_lookup_table(account:, addresses:)
      lookup_tables.add_table(account: account, addresses: addresses)
      self
    end

    # Compose the final transaction
    #
    # Emits a legacy message unless lookup tables were added, in which case a
    # v0 message is emitted instead.
    #
    # @return [Transaction] The composed transaction (unsigned)
    def compose_transaction
      context.compile

      return Solace::Transaction.new(message: legacy_message) if lookup_tables.empty?

      Solace::Transaction.new(message: versioned_message)
    end

    private

    # Build the legacy message
    #
    # @return [Solace::Message] The legacy message
    def legacy_message
      Solace::Message.new(
        header:           context.header,
        accounts:         context.accounts,
        instructions:     build_instructions,
        recent_blockhash: recent_blockhash
      )
    end

    # Build the v0 message
    #
    # Loaded accounts leave the static account list and are referenced through
    # the lookup tables. Instructions are rebuilt after the relocation so their
    # indices resolve against the combined v0 account space
    # [static..., loaded writable..., loaded readonly...] — the order in which
    # the Solana runtime flattens loaded addresses before execution.
    #
    # @return [Solace::Message] The v0 message
    def versioned_message
      writable, readonly = lookup_tables.select_loaded_accounts(context, program_ids)
      static_accounts    = context.relocate_loaded_accounts(writable.keys, readonly.keys)

      Solace::Message.new(
        version:               0,
        header:                context.header,
        accounts:              static_accounts,
        instructions:          build_instructions,
        recent_blockhash:      recent_blockhash,
        address_lookup_tables: lookup_tables.address_lookup_tables_for(writable, readonly)
      )
    end

    # Fetch a recent blockhash from the connection
    #
    # @return [String] The recent blockhash (base58)
    def recent_blockhash
      connection.get_latest_blockhash[0]
    end

    # Program ids referenced by the built instructions
    #
    # Resolved by building the instructions against the compiled static order,
    # so any program an instruction actually invokes is covered — including
    # composers that emit multiple instructions for different programs.
    #
    # @return [Array<String>] The program id pubkeys
    def program_ids
      build_instructions.map { |instruction| context.accounts[instruction.program_index] }.uniq
    end

    # Build all instructions with resolved indices
    #
    # @return [Array<Solace::Instruction>] The built instructions
    def build_instructions
      instruction_composers.map { _1.build_instruction(context) }.flatten
    end

    # Merge all accounts from another AccountContext into this one
    #
    # @param account_context [AccountContext] The other context to merge from
    def merge_accounts(account_context)
      context.merge_from(account_context)
    end
  end
end

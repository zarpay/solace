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

    # Initialize the composer
    #
    # @param connection [Solace::Connection] The connection to the Solana cluster
    def initialize(connection:)
      @connection            = connection
      @instruction_composers = []
      @context               = Utils::AccountContext.new
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

    # Compose the final transaction
    #
    # @return [Transaction] The composed transaction (unsigned)
    def compose_transaction
      context.compile

      message = Solace::Message.new(
        header:           context.header,
        accounts:         context.accounts,
        instructions:     build_instructions,
        recent_blockhash: connection.get_latest_blockhash[0]
      )

      Solace::Transaction.new(message: message)
    end

    private

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

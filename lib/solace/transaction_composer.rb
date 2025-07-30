# frozen_string_literal: true

# lib/solace/transaction_composer.rb
module Solace
  # Composes multi-instruction transactions with automatic account management
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
  # @since 0.0.1
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
      @connection = connection
      @instruction_composers = []
      @context = Utils::AccountContext.new
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

    # Set the fee payer for the transaction
    #
    # @param pubkey [String, Solace::PublicKey, Solace::Keypair] The fee payer pubkey
    # @return [TransactionComposer] Self for chaining
    def set_fee_payer(pubkey)
      context.set_fee_payer(pubkey)
      self
    end

    # Compose the final transaction
    #
    # @return [Solace::Transaction] The composed transaction (unsigned)
    def compose_transaction
      context.compile

      message = Solace::Message.new(
        header: context.header,
        accounts: context.accounts,
        instructions: build_instructions,
        recent_blockhash: connection.get_latest_blockhash
      )

      Solace::Transaction.new(message: message)
    end

    private

    # Build all instructions with resolved indices
    #
    # @return [Array<Solace::Instruction>] The built instructions
    def build_instructions
      instruction_composers.map { _1.build_instruction(context) }
    end

    # Merge all accounts from another AccountContext into this one
    #
    # @param account_context [AccountContext] The other context to merge from
    def merge_accounts(account_context)
      context.merge_from(account_context)
    end
  end
end

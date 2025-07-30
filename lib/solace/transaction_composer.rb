# frozen_string_literal: true

# lib/solace/transaction_composer.rb
module Solace
  # !@class TransactionComposer
  #   Composes multi-instruction transactions with automatic account management
  #
  # @return [Class]
  class TransactionComposer
    # @!attribute connection
    #
    # @return [Solace::Connection] The connection to the Solana cluster
    attr_reader :connection

    # @!attribute context
    #
    # @return [Utils::AccountContext] The account registry
    attr_reader :context

    # @!attribute instruction_composers
    #
    # @return [Array<Composers::Base>] The instruction composers
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

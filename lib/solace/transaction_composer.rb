# lib/solace/transaction_composer.rb
module Solace
  # Composes multi-instruction transactions with automatic account management
  class TransactionComposer

    # @!attribute connection
    #
    # @return [Solace::Connection] The connection to the Solana cluster
    attr_reader :connection

    # @!attribute transaction_context
    #
    # @return [Utils::AccountContext] The account registry
    attr_reader :transaction_context

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
      @transaction_context = Utils::AccountContext.new
    end
    
    # Add an instruction composer to the transaction
    #
    # @param composer [Composers::Base] The instruction composer
    # @return [TransactionComposer] Self for chaining
    def add_instruction(composer)
      # Merge accounts from this instruction into the transaction registry
      merge_accounts(composer.account_context)
      
      # Store composer for later instruction building
      instruction_composers << composer
      
      self
    end
    
    # Set the fee payer for the transaction
    #
    # @param pubkey [String | Solace::PublicKey | Solace::Keypair] The fee payer pubkey
    # @return [TransactionComposer] Self for chaining
    def set_fee_payer(pubkey)
      transaction_context.set_fee_payer(pubkey)

      self
    end

    # Compose the final transaction
    #
    # @return [Solace::Transaction] The composed transaction (unsigned)
    def compose_transaction
      # Compile the transaction context
      transaction_context.compile
     
      # Build all instructions with resolved indices
      instructions = instruction_composers.map do |composer|
        composer.build_instruction(transaction_context)
      end
      
      # Create message
      message = Solace::Message.new(
        instructions: instructions,
        header: transaction_context.header,
        accounts: transaction_context.accounts,
        recent_blockhash: connection.get_latest_blockhash
      )
      
      # Create transaction with signers attached for easy signing
      Solace::Transaction.new(message: message)
    end    

    private

    # Merge all accounts from another AccountContext into this one
    #
    # @param account_context [AccountContext] The other context to merge from
    def merge_accounts(account_context)
      transaction_context.merge_from(account_context)
    end
  end
end

# lib/solace/transaction_composer.rb
module Solace
  # Composes multi-instruction transactions with automatic account management
  class TransactionComposer
    def initialize(connection:)
      @connection = connection
      @registry = AccountRegistry.new
      @instruction_composers = []
    end
    
    # Add an instruction composer to the transaction
    #
    # @param composer [InstructionComposer] The instruction composer
    # @return [TransactionComposer] Self for chaining
    def add_instruction(composer)
      # Merge accounts from this instruction into the transaction registry
      account_info = composer.account_info
      merge_accounts(account_info)
      
      # Store composer for later instruction building
      @instruction_composers << composer
      
      self
    end
    
    # Compose the final transaction
    #
    # @return [Solace::Transaction] The composed transaction (unsigned)
    def compose_transaction
      # Compile all accounts and get final indices
      compiled = @registry.compile
      
      # Build all instructions with resolved indices
      instructions = @instruction_composers.map do |composer|
        composer.build_instruction(compiled[:indices])
      end
      
      # Create message
      message = Solace::Message.new(
        header: compiled[:header],
        accounts: compiled[:accounts],
        instructions: instructions,
        recent_blockhash: @connection.get_latest_blockhash
      )
      
      # Create transaction with signers attached for easy signing
      tx = Solace::Transaction.new(message: message)
      tx.instance_variable_set(:@required_signers, compiled[:signers])
      
      # Define a sign! method that signs with all required signers
      def tx.sign!
        sign(*@required_signers)
        self
      end
      
      tx
    end
    
    private
    
    def merge_accounts(account_info)
      account_info[:account_data].each do |name, data|
        @registry.merge_account(
          name,
          data[:pubkey],
          signer: data[:signer],
          writable: data[:writable],
          keypair: data[:keypair]
        )
      end
    end
  end
end

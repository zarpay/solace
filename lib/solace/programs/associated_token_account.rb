# frozen_string_literal: true

module Solace
  module Programs
    # A client for interacting with the SPL Token Program.
    class AssociatedTokenAccount < Base
      class << self
        # Gets the address of an associated token account.
        #
        # @param owner [Solace::Keypair || Solace::PublicKey] The keypair of the owner.
        # @param mint [Solace::Keypair || Solace::PublicKey] The keypair of the mint.
        # @return [String] The address of the associated token account.
        def get_address(owner:, mint:)
          Solace::Utils::PDA.find_program_address(
            [
              owner.address,
              Solace::Constants::TOKEN_PROGRAM_ID,
              mint.address
            ],
            Solace::Constants::ASSOCIATED_TOKEN_ACCOUNT_PROGRAM_ID
          )
        end
      end

      # Initializes a new Associated Token Account client.
      #
      # @param connection [Solace::Connection] The connection to the Solana cluster.
      def initialize(connection:)
        super(connection:, program_id: Solace::Constants::ASSOCIATED_TOKEN_ACCOUNT_PROGRAM_ID)
      end

      # Alias method for get_address
      # 
      # @param oprtions [Hash] A hash of options for the get_address class method
      def get_address(**options)
        self.class.get_address(**options)
      end

      # Alias method for get_address
      # 
      # @param oprtions [Hash] A hash of options for the get_address class method
      def get_address(**options)
        self.class.get_address(**options)
      end

      # Gets the address of an associated token account, creating it if it doesn't exist.
      #
      # @param payer [Solace::Keypair] The keypair that will pay for fees and rent (required if account needs to be created).
      # @param owner [Solace::Keypair || Solace::PublicKey] The keypair of the owner.
      # @param mint [Solace::Keypair || Solace::PublicKey] The keypair of the mint.
      # @return [String] The address of the associated token account
      def get_or_create_address(payer:, owner:, mint:)
        ata_address, _ = get_address(owner:, mint:)
        
        account_info = @connection.get_account_info(ata_address)
        
        return ata_address if account_info

        response = create_associated_token_account(payer:, owner:, mint:)
        @connection.wait_for_confirmed_signature { response }
        
        ata_address
      end

      # Creates a new associated token account.
      #
      # @param options [Hash] Options for calling the prepare_create_associated_token_account method.
      # @return [String] The signature of the transaction.
      def create_associated_token_account(**options)
        tx = prepare_create_associated_token_account(**options)

        @connection.send_transaction(tx.serialize)
      end

      # Prepares a new associated token account and returns the signed transaction.
      #
      # @param owner [Solace::Keypair || Solace::PublicKey] The keypair of the owner.
      # @param mint [Solace::Keypair || Solace::PublicKey] The keypair of the mint.
      # @param payer [Solace::Keypair] The keypair that will pay for fees and rent.
      # @return [Solace::Transaction] The signed transaction.
      def prepare_create_associated_token_account(
        payer:, 
        owner:, 
        mint:
      )
        ata_address, _ = get_address(owner:, mint:)

        accounts = [
          payer.address,
          ata_address,
          owner.address,
          mint.address,
          Solace::Constants::SYSTEM_PROGRAM_ID,
          Solace::Constants::TOKEN_PROGRAM_ID,
          Solace::Constants::ASSOCIATED_TOKEN_ACCOUNT_PROGRAM_ID
        ]

        instruction = Solace::Instructions::AssociatedTokenAccount::CreateAssociatedTokenAccountInstruction.build(
          funder_index: 0,
          associated_token_account_index: 1,
          owner_index: 2,
          mint_index: 3,
          system_program_index: 4,
          token_program_index: 5,
          program_index: 6
        )

        message = Solace::Message.new(
          header: [1, 0, 4],
          accounts: accounts,
          recent_blockhash: @connection.get_latest_blockhash,
          instructions: [instruction]
        )

        tx = Solace::Transaction.new(message: message)
        tx.sign(payer)

        tx
      end
    end
  end
end

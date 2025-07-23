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
        owner:,
        mint:,
        payer:
      )
        # 1. Derive the Associated Token Account (ATA) address
        ata_address, _ = get_address(owner:, mint:)

        # 2. Define the master list of accounts for the transaction in the correct order.
        accounts = [
          payer.address,          # 0: Funder (Payer), writable, signer
          ata_address,            # 1: New ATA, writable
          owner.address,          # 2: Owner, readonly
          mint.address,           # 3: Mint, readonly
          Solace::Constants::SYSTEM_PROGRAM_ID,                      # 4: System Program, readonly
          Solace::Constants::TOKEN_PROGRAM_ID,                   # 5: SPL Token Program, readonly
          Solace::Constants::ASSOCIATED_TOKEN_ACCOUNT_PROGRAM_ID # 6: The program we are calling
        ]

        # 3. Build the instruction, providing the index of each required account.
        instruction = Solace::Instructions::AssociatedTokenAccount::CreateAssociatedTokenAccountInstruction.build(
          funder_index: 0,
          associated_token_account_index: 1,
          owner_index: 2,
          mint_index: 3,
          system_program_index: 4,
          token_program_index: 5,
          program_index: 6
        )

        # 4. Build the message
        message = Solace::Message.new(
          header: [1, 0, 4], # 1 signer (payer), 4 readonly accounts
          accounts: accounts,
          recent_blockhash: @connection.get_latest_blockhash,
          instructions: [instruction]
        )

        # 5. Build and sign the transaction
        tx = Solace::Transaction.new(message: message)
        tx.sign(payer)

        tx
      end
    end
  end
end

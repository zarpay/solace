# frozen_string_literal: true

module Solace
  module Programs
    # A client for interacting with the SPL Token Program.
    class SplToken < Base
      # Initializes a new SPL Token client.
      #
      # @param connection [Solace::Connection] The connection to the Solana cluster.
      def initialize(connection:)
        super(connection: connection, program_id: Solace::Constants::TOKEN_PROGRAM_ID)
      end

      # Creates a new SPL Token mint.
      #
      # @param options [Hash] Options for calling the prepare_create_mint method.
      # @return [String] The signature of the transaction.
      def create_mint(**options)
        tx = prepare_create_mint(**options)

        @connection.send_transaction(tx.serialize)
      end

      # Prepares a new SPL Token mint and returns the signed transaction.
      #
      # @param payer [Solace::Keypair] The keypair that will pay for fees and rent.
      # @param decimals [Integer] The number of decimal places for the token.
      # @param mint_authority [String] The base58 public key for the mint authority.
      # @param freeze_authority [String] (Optional) The base58 public key for the freeze authority.
      # @param mint_keypair [Solace::Keypair] (Optional) The keypair for the new mint.
      # @return [Solace::Transaction] The signed transaction.
      def prepare_create_mint(
        payer:,
        decimals:,
        mint_authority:,
        freeze_authority:,
        mint_keypair: Solace::Keypair.generate
      )
        # 1. Specify accounts
        accounts = [
          payer.address,
          mint_keypair.address,
          Solace::Constants::SYSVAR_RENT_PROGRAM_ID,
          Solace::Constants::TOKEN_PROGRAM_ID,
          Solace::Constants::SYSTEM_PROGRAM_ID
        ]

        # 2. Build create account instruction

        # Get rent exemption cost
        rent_lamports = @connection.get_minimum_lamports_for_rent_exemption(82)

        # Create a new account for the mint.
        create_account_ix = Solace::Instructions::SystemProgram::CreateAccountInstruction.build(
          from_index: 0, # The payer is the first account
          new_account_index: 1, # The new mint is the second account
          system_program_index: 4, # The System Program is the fourth account
          lamports: rent_lamports,
          space: 82,
          owner: program_id
        )

        # 3. Build initialize mint instruction
        freeze_authority_address = freeze_authority.respond_to?(:address) ? freeze_authority.address : nil

        initialize_mint_ix = Solace::Instructions::SplToken::InitializeMintInstruction.build(
          mint_account_index: 1,
          rent_sysvar_index: 2,
          program_index: 3,
          decimals: decimals,
          mint_authority: mint_authority.address,
          freeze_authority: freeze_authority_address
        )

        # 4. Build and transaction
        message = Message.new(
          header: [2, 0, 3], # payer and mint_keypair are signers
          accounts: accounts,
          recent_blockhash: @connection.get_latest_blockhash,
          instructions: [create_account_ix, initialize_mint_ix]
        )

        tx = Transaction.new(message: message)

        # 5. Sign and return
        tx.sign(payer, mint_keypair)

        tx
      end
    end
  end
end

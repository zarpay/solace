# frozen_string_literal: true

module Solace
  module Programs
    # Client for interacting with the SPL Token Program.
    #
    # This client provides methods for interacting with the SPL Token Program. It is a wrapper around
    # the SPL Token Program and provides a more convenient interface for creating and managing SPL
    # Token mints and accounts.
    #
    # @example Create an SPL Token mint
    #   # Initialize the program with a connection
    #   program = Solace::Programs::SplToken.new(connection: connection)
    #
    #   # Create an SPL Token mint
    #   result = program.create_mint(
    #     payer: payer,
    #     decimals: 6,
    #     mint_keypair: mint_keypair,
    #     mint_authority: mint_authority,
    #     freeze_authority: freeze_authority
    #   )
    #
    #   # Wait for the transaction to be finalized
    #   @connection.wait_for_confirmed_signature('finalized') { result['result'] }
    #
    # @since 0.0.2
    #
    # rubocop:disable Metrics/ClassLength
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
      #
      # rubocop:disable Metrics/MethodLength
      def prepare_create_mint(
        payer:,
        decimals:,
        mint_authority:,
        freeze_authority:,
        mint_keypair: Solace::Keypair.generate
      )
        accounts = [
          payer.address,
          mint_keypair.address,
          Solace::Constants::SYSVAR_RENT_PROGRAM_ID,
          Solace::Constants::TOKEN_PROGRAM_ID,
          Solace::Constants::SYSTEM_PROGRAM_ID
        ]

        rent_lamports = @connection.get_minimum_lamports_for_rent_exemption(82)

        create_account_ix = Solace::Instructions::SystemProgram::CreateAccountInstruction.build(
          from_index: 0,
          new_account_index: 1,
          system_program_index: 4,
          lamports: rent_lamports,
          space: 82,
          owner: program_id
        )

        freeze_authority_address = freeze_authority.respond_to?(:address) ? freeze_authority.address : nil

        initialize_mint_ix = Solace::Instructions::SplToken::InitializeMintInstruction.build(
          mint_account_index: 1,
          rent_sysvar_index: 2,
          program_index: 3,
          decimals: decimals,
          mint_authority: mint_authority.address,
          freeze_authority: freeze_authority_address
        )

        message = Message.new(
          header: [2, 0, 3],
          accounts: accounts,
          recent_blockhash: @connection.get_latest_blockhash,
          instructions: [create_account_ix, initialize_mint_ix]
        )

        tx = Transaction.new(message: message)
        tx.sign(payer, mint_keypair)

        tx
      end
      # rubocop:enable Metrics/MethodLength

      # Mint tokens to a token account
      #
      # @param options [Hash] Options for calling the prepare_mint_to method.
      # @return [String] The signature of the transaction.
      def mint_to(**options)
        tx = prepare_mint_to(**options)

        @connection.send_transaction(tx.serialize)
      end

      # Prepares a mint to instruction and returns the signed transaction.
      #
      # @param [Integer] amount The amount of tokens to mint.
      # @param [PublicKey, Keypair, String] payer The payer of the transaction.
      # @param [PublicKey, Keypair, String] mint The mint of the token.
      # @param [PublicKey, Keypair, String] destination The destination of the token.
      # @param [PublicKey, Keypair, String] mint_authority The mint authority of the token.
      # @return [Solace::Transaction] The signed transaction.
      #
      # rubocop:disable Metrics/MethodLength
      def prepare_mint_to(
        payer:,
        mint:,
        destination:,
        amount:,
        mint_authority:
      )
        accounts = [
          payer.address,
          mint_authority.address,
          mint.address,
          destination,
          Solace::Constants::TOKEN_PROGRAM_ID
        ]

        ix = Solace::Instructions::SplToken::MintToInstruction.build(
          amount: amount,
          mint_authority_index: 1,
          mint_index: 2,
          destination_index: 3,
          program_index: 4
        )

        message = Solace::Message.new(
          header: [2, 0, 1],
          accounts: accounts,
          instructions: [ix],
          recent_blockhash: connection.get_latest_blockhash
        )

        tx = Solace::Transaction.new(message: message)
        tx.sign(payer, mint_authority)

        tx
      end
      # rubocop:enable Metrics/MethodLength

      # Transfers tokens from one account to another
      #
      # @param options [Hash] Options for calling the prepare_transfer method.
      # @return [String] The signature of the transaction.
      def transfer(**options)
        tx = prepare_transfer(**options)

        @connection.send_transaction(tx.serialize)
      end

      # Prepares a transfer instruction and returns the signed transaction.
      #
      # @param payer [Solace::Keypair] The keypair that will pay for fees and rent.
      # @param source [String] The source token account address.
      # @param destination [String] The destination token account address.
      # @param amount [Integer] The number of tokens to transfer.
      # @param owner [Solace::Keypair] The keypair of the owner of the source account.
      # @return [Solace::Transaction] The signed transaction.
      #
      # rubocop:disable Metrics/MethodLength
      def prepare_transfer(
        amount:,
        payer:,
        source:,
        destination:,
        owner:
      )
        accounts = [
          payer.address,
          owner.address,
          source,
          destination,
          Solace::Constants::TOKEN_PROGRAM_ID
        ]

        ix = Solace::Instructions::SplToken::TransferInstruction.build(
          amount: amount,
          owner_index: 1,
          source_index: 2,
          destination_index: 3,
          program_index: 4
        )

        message = Solace::Message.new(
          header: [2, 0, 1],
          accounts: accounts,
          instructions: [ix],
          recent_blockhash: connection.get_latest_blockhash
        )

        tx = Solace::Transaction.new(message: message)
        tx.sign(payer, owner)

        tx
      end
      # rubocop:enable Metrics/MethodLength
    end
    # rubocop:enable Metrics/ClassLength
  end
end

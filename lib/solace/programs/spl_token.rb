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

        tx.sign(
          options[:payer],
          options[:mint_account]
        )

        @connection.send_transaction(tx.serialize)
      end

      # Prepares a new SPL Token mint transaction.
      #
      # @param payer [#to_s, Solace::PublicKey] The payer that will pay for fees and rent.
      # @param decimals [Integer] The number of decimal places for the token.
      # @param mint_authority [#to_s, Solace::PublicKey] The base58 public key for the mint authority.
      # @param freeze_authority [#to_s, Solace::PublicKey] (Optional) The base58 public key for the freeze authority.
      # @param mint_account [#to_s, Solace::PublicKey] (Optional) The keypair for the new mint.
      # @return [Solace::Transaction] The signed transaction.
      #
      # rubocop:disable Metrics/MethodLength
      def prepare_create_mint(
        payer:,
        decimals:,
        mint_authority:,
        freeze_authority:,
        mint_account: Solace::Keypair.generate
      )
        # Mint accounts need 82 bytes of space, and we need to fund it with enough lamports to be rent-exempt
        rent_lamports = @connection.get_minimum_lamports_for_rent_exemption(82)

        # Build the account for the mint
        create_account_ix = Composers::SystemProgramCreateAccountComposer.new(
          from: payer,
          new_account: mint_account,
          owner: program_id,
          lamports: rent_lamports,
          space: 82
        )

        # Build the initialize mint composer
        initialize_mint_ix = Composers::SplTokenProgramInitializeMintComposer.new(
          decimals: decimals,
          mint_account: mint_account,
          mint_authority: mint_authority,
          freeze_authority: freeze_authority
        )

        TransactionComposer
          .new(connection: @connection)
          .add_instruction(create_account_ix)
          .add_instruction(initialize_mint_ix)
          .set_fee_payer(payer)
          .compose_transaction
      end
      # rubocop:enable Metrics/MethodLength

      # Mint tokens to a token account
      #
      # @param options [Hash] Options for calling the prepare_mint_to method.
      # @return [String] The signature of the transaction.
      def mint_to(**options)
        tx = prepare_mint_to(**options)

        tx.sign(
          options[:payer],
          options[:mint_authority]
        )

        @connection.send_transaction(tx.serialize)
      end

      # Prepares a mint to instruction and returns the signed transaction.
      #
      # @param [Integer] amount The amount of tokens to mint.
      # @param [#to_s, PublicKey] payer The payer of the transaction.
      # @param [#to_s, PublicKey] mint The mint of the token.
      # @param [#to_s, PublicKey] destination The destination of the token.
      # @param [#to_s, PublicKey] mint_authority The mint authority of the token.
      # @return [Solace::Transaction] The signed transaction.
      #
      # @param [Boolean] ensure_account
      def prepare_mint_to(
        payer:,
        mint:,
        amount:,
        destination:,
        mint_authority:
      )
        ix = Solace::Composers::SplTokenProgramMintToComposer.new(
          amount: amount,
          mint: mint,
          destination: destination,
          mint_authority: mint_authority
        )

        TransactionComposer
          .new(connection: connection)
          .add_instruction(ix)
          .set_fee_payer(payer)
          .compose_transaction
      end

      # Transfers tokens from one account to another
      #
      # @param options [Hash] Options for calling the prepare_transfer method.
      # @return [String] The signature of the transaction.
      def transfer(**options)
        tx = prepare_transfer(**options)

        tx.sign(
          options[:payer],
          options[:owner]
        )

        @connection.send_transaction(tx.serialize)
      end

      # Prepares a transfer instruction and returns the signed transaction.
      #
      # @param payer [#to_s, Solace::PublicKey] The keypair that will pay for fees and rent.
      # @param source [String] The source token account address.
      # @param destination [String] The destination token account address.
      # @param amount [Integer] The number of tokens to transfer.
      # @param owner [#to_s, Solace::PublicKey] The keypair of the owner of the source account.
      # @return [Solace::Transaction] The signed transaction.
      #
      def prepare_transfer(
        amount:,
        payer:,
        source:,
        destination:,
        owner:
      )
        ix = Solace::Composers::SplTokenProgramTransferComposer.new(
          amount: amount,
          owner: owner,
          source: source,
          destination: destination
        )

        TransactionComposer
          .new(connection: connection)
          .add_instruction(ix)
          .set_fee_payer(payer)
          .compose_transaction
      end
    end
  end
end

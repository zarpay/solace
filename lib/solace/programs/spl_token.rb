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
    #   connection.wait_for_confirmed_signature('finalized') { result['result'] }
    #
    # @since 0.0.2
    class SplToken < Base
      # Initializes a new SPL Token client.
      #
      # @param connection [Solace::Connection] The connection to the Solana cluster.
      def initialize(connection:)
        super(connection: connection, program_id: Solace::Constants::TOKEN_PROGRAM_ID)
      end

      # Creates a new SPL Token mint.
      #
      # @param payer [#to_s, PublicKey] The keypair that will pay for fees and rent.
      # @param sign [Boolean] Whether to sign the transaction.
      # @param execute [Boolean] Whether to execute the transaction.
      # @param composer_opts [Hash] Options for calling the compose_create_mint method.
      # @return [String] The signature of the transaction.
      def create_mint(
        payer:,
        sign: true,
        execute: true,
        **composer_opts
      )
        composer = compose_create_mint(**composer_opts)

        yield composer if block_given?

        tx = composer
             .set_fee_payer(payer)
             .compose_transaction

        if sign
          tx.sign(
            payer,
            composer_opts[:funder],
            composer_opts[:mint_account]
          )

          connection.send_transaction(tx.serialize) if execute
        end

        tx
      end

      # Prepares a new SPL Token mint transaction.
      #
      # @param funder [#to_s, PublicKey] The keypair that will pay for rent of the new mint account.
      # @param decimals [Integer] The number of decimal places for the token.
      # @param mint_authority [#to_s, PublicKey] The base58 public key for the mint authority.
      # @param freeze_authority [#to_s, PublicKey] (Optional) The base58 public key for the freeze authority.
      # @param mint_account [#to_s, PublicKey] (Optional) The keypair for the new mint.
      # @return [TransactionComposer] A composer with required instructions.
      #
      # rubocop:disable Metrics/MethodLength
      def compose_create_mint(
        funder:,
        decimals:,
        mint_authority:,
        freeze_authority: nil,
        mint_account: Solace::Keypair.generate
      )
        # Mint accounts need 82 bytes of space, and we need to fund it with enough lamports to be rent-exempt
        rent_lamports = connection.get_minimum_lamports_for_rent_exemption(82)

        # Build the account for the mint
        create_account_ix = Composers::SystemProgramCreateAccountComposer.new(
          from: funder,
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
      end
      # rubocop:enable Metrics/MethodLength

      # Mint tokens to a token account
      #
      # @param payer [#to_s, PublicKey] The keypair that will pay for fees and rent.
      # @param sign [Boolean] Whether to sign the transaction.
      # @param execute [Boolean] Whether to execute the transaction.
      # @param composer_opts [Hash] Options for calling the compose_mint_to method.
      # @return [String] The signature of the transaction.
      def mint_to(
        payer:,
        sign: true,
        execute: true,
        **composer_opts
      )
        composer = compose_mint_to(**composer_opts)

        yield composer if block_given?

        tx = composer
             .set_fee_payer(payer)
             .compose_transaction

        if sign
          tx.sign(
            payer,
            composer_opts[:mint_authority]
          )

          connection.send_transaction(tx.serialize) if execute
        end

        tx
      end

      # Prepares a mint to instruction and returns the signed transaction.
      #
      # @param [Integer] amount The amount of tokens to mint.
      # @param [#to_s, PublicKey] mint The mint of the token.
      # @param [#to_s, PublicKey] destination The destination of the token.
      # @param [#to_s, PublicKey] mint_authority The mint authority of the token.
      # @return [TransactionComposer] A composer with required instructions.
      #
      # @param [Boolean] ensure_account
      def compose_mint_to(
        mint:,
        amount:,
        destination:,
        mint_authority:
      )
        ix = Composers::SplTokenProgramMintToComposer.new(
          amount: amount,
          mint: mint,
          destination: destination,
          mint_authority: mint_authority
        )

        TransactionComposer
          .new(connection: connection)
          .add_instruction(ix)
      end

      # Transfers tokens from one account to another
      #
      # @param payer [#to_s, PublicKey] The keypair that will pay for fees and rent.
      # @param sign [Boolean] Whether to sign the transaction.
      # @param execute [Boolean] Whether to execute the transaction.
      # @param composer_opts [Hash] Options for calling the compose_transfer method.
      # @return [String] The signature of the transaction.
      def transfer(
        payer:,
        sign: true,
        execute: true,
        **composer_opts
      )
        composer = compose_transfer(**composer_opts)

        yield composer if block_given?

        tx = composer
             .set_fee_payer(payer)
             .compose_transaction

        if sign
          tx.sign(
            payer,
            composer_opts[:owner]
          )

          connection.send_transaction(tx.serialize) if execute
        end
        tx
      end

      # Prepares a transfer instruction and returns the signed transaction.
      #
      # @param source [#to_s, PublicKey] The source token account address.
      # @param destination [#to_s, PublicKey] The destination token account address.
      # @param amount [Integer] The number of tokens to transfer.
      # @param owner [#to_s, PublicKey] The keypair of the owner of the source account.
      # @return [TransactionComposer] A composer with required instructions.
      #
      def compose_transfer(
        amount:,
        source:,
        destination:,
        owner:
      )
        ix = Composers::SplTokenProgramTransferComposer.new(
          amount: amount,
          owner: owner,
          source: source,
          destination: destination
        )

        TransactionComposer
          .new(connection: connection)
          .add_instruction(ix)
      end

      # Additionally, we can implement a way to add additional instructions to the composer
      # from the actual program methods by yielding the composer before signing and composing
      # the final transaction. The sign and send methods may also allow for a option to disable
      # sending, and simply return the signed transaction instead.

      # Transfers tokens with decimal precision and validation checks
      #
      # @param payer [#to_s, PublicKey] The keypair that will pay for fees and rent.
      # @param sign [Boolean] Whether to sign the transaction.
      # @param execute [Boolean] Whether to execute the transaction.
      # @param composer_opts [Hash] Options for calling the compose_transfer_checked method.
      # @return [String] The signature of the transaction.
      def transfer_checked(
        payer:,
        sign: true,
        execute: true,
        **composer_opts
      )
        composer = compose_transfer_checked(**composer_opts)

        yield composer if block_given?

        tx = composer
             .set_fee_payer(payer)
             .compose_transaction

        if sign
          tx.sign(
            payer,
            composer_opts[:authority]
          )

          connection.send_transaction(tx.serialize) if execute
        end

        tx
      end

      # Prepares a transfer checked instruction and returns the signed transaction.
      #
      # @param amount [Integer] The number of tokens to transfer.
      # @param decimals [Integer] The number of decimals for the token.
      # @param from [#to_s, PublicKey] The source token account address.
      # @param to [#to_s, PublicKey] The destination token account address.
      # @param mint [#to_s, PublicKey] The mint address
      # @param authority [#to_s, PublicKey] The keypair of the owner of the source account.
      # @return [TransactionComposer] A composer with required instructions.
      def compose_transfer_checked(
        to:,
        from:,
        mint:,
        authority:,
        amount:,
        decimals:
      )
        ix = Composers::SplTokenProgramTransferCheckedComposer.new(
          to: to,
          from: from,
          mint: mint,
          authority: authority,
          amount: amount,
          decimals: decimals
        )

        TransactionComposer
          .new(connection: connection)
          .add_instruction(ix)
      end
    end
  end
end

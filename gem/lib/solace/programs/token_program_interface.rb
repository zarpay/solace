# frozen_string_literal: true

module Solace
  module Programs
    # Mixin describing the common surface of a token-program client.
    #
    # The legacy SPL Token program and Token-2022 expose a wire-compatible
    # base instruction set (Transfer, TransferChecked, CloseAccount, MintTo,
    # InitializeMint). This module captures the *shape* of a client that
    # speaks that surface — the public methods +create_mint+, +mint_to+,
    # +transfer+, +transfer_checked+ and their +compose_*+ pairs — without
    # binding to either program.
    #
    # State (connection, program_id) lives on {Programs::Base}; this module
    # is purely behavior. Including classes must implement four private
    # readers that name the composer class for each operation:
    #
    # - {#initialize_mint_composer_class}
    # - {#mint_to_composer_class}
    # - {#transfer_composer_class}
    # - {#transfer_checked_composer_class}
    #
    # Each composer returned by those readers is itself bound to a single
    # on-chain program, which is how this mixin keeps the boundary clean:
    # +SplToken+ and +Token2022+ share *methods* but never share a composer.
    #
    # @see Solace::Programs::SplToken
    # @see Solace::Programs::Token2022
    # @since 0.1.5
    # rubocop:disable Metrics/ModuleLength
    module TokenProgramInterface
      # Creates a new mint, signs it, and (optionally) sends it.
      #
      # @param payer [#to_s, PublicKey] The keypair that will pay for fees and rent.
      # @param sign [Boolean] Whether to sign the transaction.
      # @param execute [Boolean] Whether to execute the transaction.
      # @param composer_opts [Hash] Options for {#compose_create_mint}.
      # @return [Transaction] The created or sent transaction.
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

      # Prepares a new mint transaction.
      #
      # @param funder [#to_s, PublicKey] The keypair that will pay for rent of the new mint account.
      # @param decimals [Integer] The number of decimal places for the token.
      # @param mint_authority [#to_s, PublicKey] The base58 public key for the mint authority.
      # @param freeze_authority [#to_s, PublicKey] (Optional) The base58 public key for the freeze authority.
      # @param mint_account [#to_s, PublicKey] (Optional) The keypair for the new mint.
      # @return [TransactionComposer] A composer with required instructions.
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
          from:        funder,
          new_account: mint_account,
          owner:       program_id,
          lamports:    rent_lamports,
          space:       82
        )

        # Build the initialize mint composer (per-program class supplied by includer)
        initialize_mint_ix = initialize_mint_composer_class.new(
          decimals:         decimals,
          mint_account:     mint_account,
          mint_authority:   mint_authority,
          freeze_authority: freeze_authority
        )

        TransactionComposer
          .new(connection: connection)
          .add_instruction(create_account_ix)
          .add_instruction(initialize_mint_ix)
      end
      # rubocop:enable Metrics/MethodLength

      # Mints tokens to a token account.
      #
      # @param payer [#to_s, PublicKey] The keypair that will pay for fees and rent.
      # @param sign [Boolean] Whether to sign the transaction.
      # @param execute [Boolean] Whether to execute the transaction.
      # @param composer_opts [Hash] Options for {#compose_mint_to}.
      # @return [Transaction] The created or sent transaction.
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

      # Prepares a mint_to instruction.
      #
      # @param amount [Integer] The amount of tokens to mint.
      # @param mint [#to_s, PublicKey] The mint of the token.
      # @param destination [#to_s, PublicKey] The destination token account.
      # @param mint_authority [#to_s, PublicKey] The mint authority.
      # @return [TransactionComposer] A composer with the mint_to instruction.
      def compose_mint_to(
        mint:,
        amount:,
        destination:,
        mint_authority:
      )
        ix = mint_to_composer_class.new(
          amount:         amount,
          mint:           mint,
          destination:    destination,
          mint_authority: mint_authority
        )

        TransactionComposer
          .new(connection: connection)
          .add_instruction(ix)
      end

      # Transfers tokens from one account to another.
      #
      # @param payer [#to_s, PublicKey] The keypair that will pay for fees and rent.
      # @param sign [Boolean] Whether to sign the transaction.
      # @param execute [Boolean] Whether to execute the transaction.
      # @param composer_opts [Hash] Options for {#compose_transfer}.
      # @return [Transaction] The created or sent transaction.
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

      # Prepares a transfer instruction.
      #
      # @param source [#to_s, PublicKey] The source token account address.
      # @param destination [#to_s, PublicKey] The destination token account address.
      # @param amount [Integer] The number of tokens to transfer.
      # @param owner [#to_s, PublicKey] The owner of the source account.
      # @return [TransactionComposer] A composer with the transfer instruction.
      def compose_transfer(
        amount:,
        source:,
        destination:,
        owner:
      )
        ix = transfer_composer_class.new(
          amount:      amount,
          owner:       owner,
          source:      source,
          destination: destination
        )

        TransactionComposer
          .new(connection: connection)
          .add_instruction(ix)
      end

      # Transfers tokens with decimal precision and validation checks.
      #
      # @param payer [#to_s, PublicKey] The keypair that will pay for fees and rent.
      # @param sign [Boolean] Whether to sign the transaction.
      # @param execute [Boolean] Whether to execute the transaction.
      # @param composer_opts [Hash] Options for {#compose_transfer_checked}.
      # @return [Transaction] The created or sent transaction.
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

      # Prepares a transfer_checked instruction.
      #
      # @param amount [Integer] The number of tokens to transfer.
      # @param decimals [Integer] The number of decimals for the token.
      # @param from [#to_s, PublicKey] The source token account address.
      # @param to [#to_s, PublicKey] The destination token account address.
      # @param mint [#to_s, PublicKey] The mint address.
      # @param authority [#to_s, PublicKey] The owner of the source account.
      # @return [TransactionComposer] A composer with the transfer_checked instruction.
      def compose_transfer_checked(
        to:,
        from:,
        mint:,
        authority:,
        amount:,
        decimals:
      )
        ix = transfer_checked_composer_class.new(
          to:        to,
          from:      from,
          mint:      mint,
          authority: authority,
          amount:    amount,
          decimals:  decimals
        )

        TransactionComposer
          .new(connection: connection)
          .add_instruction(ix)
      end

      private

      # @return [Class] Composer class used by {#compose_create_mint}.
      def initialize_mint_composer_class
        raise NotImplementedError, "#{self.class} must implement #initialize_mint_composer_class"
      end

      # @return [Class] Composer class used by {#compose_mint_to}.
      def mint_to_composer_class
        raise NotImplementedError, "#{self.class} must implement #mint_to_composer_class"
      end

      # @return [Class] Composer class used by {#compose_transfer}.
      def transfer_composer_class
        raise NotImplementedError, "#{self.class} must implement #transfer_composer_class"
      end

      # @return [Class] Composer class used by {#compose_transfer_checked}.
      def transfer_checked_composer_class
        raise NotImplementedError, "#{self.class} must implement #transfer_checked_composer_class"
      end
    end
    # rubocop:enable Metrics/ModuleLength
  end
end

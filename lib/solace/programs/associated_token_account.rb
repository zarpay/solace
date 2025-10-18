# frozen_string_literal: true

# The AssociatedTokenAccount program is a Solana program that provides a standardized way to create and manage token accounts.
#
# This class provides a Ruby interface to the Associated Token Account program, allowing you to easily
# find or create associated token accounts for a given wallet and mint.
#
# @see https://spl.solana.com/associated-token-account Solana Associated Token Account Program
#
# @author Sebastian Scholl
# @since 0.1.0
module Solace
  module Programs
    # Client for interacting with the Associated Token Account Program.
    #
    # This client provides methods for interacting with the Associated Token Account Program. It is a
    # wrapper around the SPL Token Program and provides a more convenient interface for creating and
    # managing associated token accounts.
    #
    # @example Create an associated token account
    #   # Initialize the program with a connection
    #   program = Solace::Programs::AssociatedTokenAccount.new(connection: connection)
    #
    #   # Create an associated token account
    #   result = program.create_associated_token_account(
    #     payer: payer,
    #     funder: funder,
    #     owner: owner,
    #     mint: mint
    #   )
    #
    #   # Wait for the transaction to be finalized
    #   connection.wait_for_confirmed_signature('finalized') { result['result'] }
    #
    # @since 0.0.2
    class AssociatedTokenAccount < Base
      class << self
        # Gets the address of an associated token account.
        #
        # @param owner [Keypair, PublicKey] The keypair of the owner.
        # @param mint [Keypair, PublicKey] The keypair of the mint.
        # @return [String] The address of the associated token account.
        def get_address(owner:, mint:)
          Solace::Utils::PDA.find_program_address(
            [
              owner.to_s,
              Solace::Constants::TOKEN_PROGRAM_ID,
              mint.to_s
            ],
            Solace::Constants::ASSOCIATED_TOKEN_ACCOUNT_PROGRAM_ID
          )
        end
      end

      # Initializes a new Associated Token Account client.
      #
      # @param connection [Solace::Connection] The connection to the Solana cluster.
      def initialize(connection:)
        super(connection: connection, program_id: Solace::Constants::ASSOCIATED_TOKEN_ACCOUNT_PROGRAM_ID)
      end

      # Alias method for get_address
      #
      # @param options [Hash] A hash of options for the get_address class method
      # @return [Array<String, Integer>] The address of the associated token account and the bump seed
      def get_address(**options)
        self.class.get_address(**options)
      end

      # Gets the address of an associated token account, creating it if it doesn't exist.
      #
      # @param payer [Keypair] The keypair that will pay for fees and rent.
      # @param funder [Keypair] The keypair that will pay for rent of the new associated token account.
      # @param owner [Keypair, PublicKey] The keypair of the owner.
      # @param mint [Keypair, PublicKey] The keypair of the mint.
      # @return [String] The address of the associated token account
      def get_or_create_address(
        payer:,
        funder:,
        owner:,
        mint:
      )
        ata_address, = get_address(owner: owner, mint: mint)

        account_balance = connection.get_account_info(ata_address)

        return ata_address unless account_balance.nil?

        tx = create_associated_token_account(
          payer: payer,
          funder: funder,
          owner: owner,
          mint: mint
        )

        connection.wait_for_confirmed_signature { tx.signature }

        ata_address
      end

      # Creates a new associated token account.
      #
      # @param payer [#to_s, Keypair] The keypair that will pay for fees and rent.
      # @param sign [Boolean] Whether to sign the transaction before sending it.
      # @param execute [Boolean] Whether to send the transaction to the cluster.
      # @param composer_opts [Hash] Options for calling the compose_create_associated_token_account method.
      # @return [Transaction] The created or sent transaction.
      def create_associated_token_account(
        payer:,
        sign: true,
        execute: true,
        **composer_opts
      )
        composer = compose_create_associated_token_account(**composer_opts)

        yield composer if block_given?

        tx = composer
             .set_fee_payer(payer)
             .compose_transaction

        if sign
          tx.sign(
            payer,
            composer_opts[:funder]
          )

          connection.send_transaction(tx.serialize) if execute
        end

        tx
      end

      # Prepares a new associated token account and returns the signed transaction.
      #
      # @param owner [#to_s, PublicKey] The keypair of the owner.
      # @param mint [#to_s, PublicKey] The keypair of the mint.
      # @param funder [#to_s, PublicKey] The keypair that will pay for rent of the new associated token account.
      # @return [Transaction] The signed transaction.
      def compose_create_associated_token_account(
        funder:,
        owner:,
        mint:
      )
        ata_address, = get_address(owner: owner, mint: mint)

        ix = Solace::Composers::AssociatedTokenAccountProgramCreateAccountComposer.new(
          mint: mint,
          owner: owner,
          funder: funder,
          ata_address: ata_address
        )

        TransactionComposer
          .new(connection: connection)
          .add_instruction(ix)
      end
    end
  end
end

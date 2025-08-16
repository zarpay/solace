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
    #     owner: owner,
    #     mint: mint
    #   )
    #
    #   # Wait for the transaction to be finalized
    #   @connection.wait_for_confirmed_signature('finalized') { result['result'] }
    #
    # @since 0.0.2
    class AssociatedTokenAccount < Base
      class << self
        # Gets the address of an associated token account.
        #
        # @param owner [Solace::Keypair, Solace::PublicKey] The keypair of the owner.
        # @param mint [Solace::Keypair, Solace::PublicKey] The keypair of the mint.
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
      # @param payer [Solace::Keypair] The keypair that will pay for fees and rent.
      # @param owner [Solace::Keypair, Solace::PublicKey] The keypair of the owner.
      # @param mint [Solace::Keypair, Solace::PublicKey] The keypair of the mint.
      # @param commitment [String] The commitment level for the get_account_info call.
      # @return [String] The address of the associated token account
      def get_or_create_address(payer:, owner:, mint:, commitment: 'confirmed')
        ata_address, _bump = get_address(owner: owner, mint: mint)

        account_balance = @connection.get_account_info(ata_address)

        return ata_address unless account_balance.nil?

        response = create_associated_token_account(payer: payer, owner: owner, mint: mint)

        raise 'Failed to create associated token account' unless response['result']

        @connection.wait_for_confirmed_signature(commitment) { response }

        ata_address
      end

      # Creates a new associated token account.
      #
      # @param options [Hash] Options for calling the prepare_create_associated_token_account method.
      # @return [String] The signature of the transaction.
      def create_associated_token_account(**options)
        tx = prepare_create_associated_token_account(**options)

        tx.sign(options[:payer])

        @connection.send_transaction(tx.serialize)
      end

      # Prepares a new associated token account and returns the signed transaction.
      #
      # @param owner [Solace::Keypair, Solace::PublicKey] The keypair of the owner.
      # @param mint [Solace::Keypair, Solace::PublicKey] The keypair of the mint.
      # @param payer [Solace::Keypair] The keypair that will pay for fees and rent.
      # @return [Solace::Transaction] The signed transaction.
      #
      def prepare_create_associated_token_account(
        payer:,
        owner:,
        mint:
      )
        ata_address, = get_address(owner: owner, mint: mint)

        ix = Solace::Composers::AssociatedTokenAccountProgramCreateAccountComposer.new(
          mint: mint,
          owner: owner,
          funder: payer,
          ata_address: ata_address
        )

        TransactionComposer
          .new(connection: connection)
          .set_fee_payer(payer)
          .add_instruction(ix)
          .compose_transaction
      end
    end
  end
end

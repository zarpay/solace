# frozen_string_literal: true

module Solace
  module Programs
    # Client for interacting with the legacy SPL Token Program.
    #
    # This client provides methods for creating mints, minting tokens, and
    # transferring tokens via the legacy SPL Token program
    # (+TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA+). The shared method shape
    # comes from {TokenProgramInterface}; this class supplies the SPL-bound
    # composer classes.
    #
    # @example Create an SPL Token mint
    #   # Initialize the program with a connection
    #   program = Solace::Programs::SplToken.new(connection: connection)
    #
    #   # Create an SPL Token mint
    #   result = program.create_mint(
    #     payer: payer,
    #     funder: funder,
    #     decimals: 6,
    #     mint_keypair: mint_keypair,
    #     mint_authority: mint_authority,
    #     freeze_authority: freeze_authority
    #   )
    #
    #   # Wait for the transaction to be finalized
    #   connection.wait_for_confirmed_signature('finalized') { result['result'] }
    #
    # @see Solace::Programs::Token2022 for the Token-2022 successor program.
    # @since 0.0.2
    class SplToken < Base
      include TokenProgramInterface

      # Initializes a new SPL Token client.
      #
      # @param connection [Solace::Connection] The connection to the Solana cluster.
      def initialize(connection:)
        super(connection: connection, program_id: Solace::Constants::TOKEN_PROGRAM_ID)
      end

      private

      def initialize_mint_composer_class
        Composers::SplTokenProgramInitializeMintComposer
      end

      def mint_to_composer_class
        Composers::SplTokenProgramMintToComposer
      end

      def transfer_composer_class
        Composers::SplTokenProgramTransferComposer
      end

      def transfer_checked_composer_class
        Composers::SplTokenProgramTransferCheckedComposer
      end
    end
  end
end

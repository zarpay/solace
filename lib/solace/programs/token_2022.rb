# frozen_string_literal: true

module Solace
  module Programs
    # Client for interacting with the Token-2022 Program (formerly Token Extensions).
    #
    # Token-2022 is the successor to the legacy SPL Token program
    # (+TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb+). Its base instructions —
    # Transfer, TransferChecked, CloseAccount, MintTo, InitializeMint — are
    # wire-compatible with the legacy program; only the program account they
    # target is different. The shared method shape comes from
    # {TokenProgramInterface}; this class supplies the Token-2022-bound
    # composer classes. Branching between SPL Token and Token-2022 belongs at
    # the call site, where the developer already knows which mint they hold.
    #
    # Important: mints owned by Token-2022 (e.g. PYUSD on Solana) derive
    # their Associated Token Accounts with this program ID in the seed.
    # When working with such a mint, pass
    # +token_program_id: Solace::Constants::TOKEN_2022_PROGRAM_ID+ to
    # {Programs::AssociatedTokenAccount.get_address}. Use
    # {Connection#get_mint_program_id} to discover which token program owns
    # a given mint at runtime.
    #
    # This class does not yet expose the Token-2022 extension instructions
    # (transfer hooks, transfer fees, confidential transfer, etc.); those
    # are out of scope for the base instruction surface.
    #
    # @example Create a Token-2022 mint
    #   program = Solace::Programs::Token2022.new(connection: connection)
    #
    #   tx = program.create_mint(
    #     payer: payer,
    #     funder: funder,
    #     decimals: 6,
    #     mint_account: mint_account,
    #     mint_authority: mint_authority
    #   )
    #
    # @see Solace::Programs::SplToken
    # @since 0.1.5
    class Token2022 < Base
      include TokenProgramInterface

      # Initializes a new Token-2022 client.
      #
      # @param connection [Solace::Connection] The connection to the Solana cluster.
      def initialize(connection:)
        super(connection: connection, program_id: Solace::Constants::TOKEN_2022_PROGRAM_ID)
      end

      private

      def initialize_mint_composer_class
        Composers::Token2022ProgramInitializeMintComposer
      end

      def mint_to_composer_class
        Composers::Token2022ProgramMintToComposer
      end

      def transfer_composer_class
        Composers::Token2022ProgramTransferComposer
      end

      def transfer_checked_composer_class
        Composers::Token2022ProgramTransferCheckedComposer
      end
    end
  end
end

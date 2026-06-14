# frozen_string_literal: true

module Solace
  # The Composers module contains classes responsible for building and ordering
  # the accounts and instructions required for common Solana operations.
  #
  # Composers abstract away the complexity of account ordering, permission management,
  # and instruction data construction. They provide a high-level interface for
  # creating instructions that interact with on-chain programs. Each composer
  # corresponds to a specific program instruction (e.g., transferring SOL,
  # minting tokens, creating accounts).
  #
  # Composers handle:
  # - Account resolution and ordering
  # - Permission flags (signer, writable)
  # - Account deduplication
  # - Instruction data formatting
  #
  # @example Using a composer
  #   # Initialize a transaction composer
  #   composer = TransactionComposer.new(connection: connection)
  #
  #   # Create a transfer instruction composer
  #   ix = Solace::Composers::SystemProgramTransferComposer.new(
  #     from: sender.public_key,
  #     to: recipient.public_key,
  #     lamports: 1_000_000
  #   )
  #
  #   # Add the instruction to the transaction composer and compose the transaction
  #   tx = composer
  #     .add_instruction(ix)
  #     .set_fee_payer(sender.public_key)
  #     .compose_transaction
  #
  # @see Solace::TransactionComposer
  # @see Solace::Composers::Base
  # @since 0.0.3
  module Composers
    # A Base class for all composers
    #
    # @since 0.0.3
    class Base
      # @!attribute  params
      #   The params for the composer
      #
      # @return [Hash] The parameters passed to the composer
      attr_reader :params

      # @!attribute  account_context
      #   The account_context for the composer
      #
      # @return [Utils::AccountContext] The AccountContext instance for the composer
      attr_reader :account_context

      # Initialize the composer
      #
      # @param params [Hash] Parameters to pass to the composer constructor
      def initialize(params)
        @params = params
        @account_context = Utils::AccountContext.new
        setup_accounts
      end

      # Setup accounts required for this instruction
      #
      # @return [void]
      def setup_accounts
        raise NotImplementedError, 'Subclasses must implement setup_accounts method'
      end

      # Build instruction with resolved account indices
      #
      # @return [void]
      def build_instruction(indices)
        raise NotImplementedError, 'Subclasses must implement build_instruction method'
      end
    end
  end
end

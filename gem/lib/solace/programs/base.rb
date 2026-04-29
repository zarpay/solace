# frozen_string_literal: true

# lib/solace/programs/base.rb

module Solace
  # The Programs module contains high-level interfaces to Solana on-chain programs.
  #
  # Programs in this module provide convenient methods for interacting with
  # on-chain programs without needing to manually construct instructions or
  # manage account ordering. They serve as a bridge between the low-level
  # instruction builders and high-level application code.
  #
  # Each program class corresponds to a specific on-chain program:
  # - {Solace::Programs::SplToken} - SPL Token Program
  # - {Solace::Programs::AssociatedTokenAccount} - Associated Token Account Program
  #
  # @example Using a program interface
  #   token_program = Solace::Programs::SplToken.new(connection)
  #   token_program.transfer(
  #     to:,
  #     from:,
  #     owner:,
  #     amount:
  #   )
  #
  # @see Solace::Programs::SplToken
  # @see Solace::Programs::AssociatedTokenAccount
  # @since 0.0.2
  module Programs
    # Base class for program-specific clients.
    #
    # Provides a consistent interface for interacting with on-chain programs.
    #
    # @abstract
    # @see Solace::Programs::SplToken
    # @see Solace::Programs::AssociatedTokenAccount
    # @since 0.0.2
    class Base
      attr_reader :connection, :program_id

      # Initializes a new program client.
      #
      # @param connection [Solace::Connection] The connection to the Solana cluster.
      # @param program_id [String] The base58 public key of the on-chain program.
      def initialize(connection:, program_id:)
        @connection = connection
        @program_id = program_id
      end
    end
  end
end

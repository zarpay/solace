# frozen_string_literal: true

# lib/solace/programs/base.rb

module Solace
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

# frozen_string_literal: true

module Solace
  module Errors
    # Raised when a transaction being waited on reaches the awaited commitment
    # with an error. The failure is part of the ledger at that commitment, so
    # the transaction will never succeed and waiting longer cannot change it.
    #
    # @example Handling a failed transaction
    #   begin
    #     connection.wait_for_confirmed_signature('confirmed') { signature }
    #   rescue Solace::Errors::TransactionFailed => e
    #     puts "Transaction #{e.signature} failed: #{e.transaction_error}"
    #   end
    #
    # @since 0.1.10
    class TransactionFailed < Error
      attr_reader :signature, :commitment, :transaction_error

      # @param [String] message The error message
      # @param [String] signature The signature of the transaction
      # @param [String] commitment The commitment the failure was reported at
      # @param [Hash, String] transaction_error The `err` the node reported
      def initialize(message, signature:, commitment:, transaction_error:)
        super(message)
        @signature         = signature
        @commitment        = commitment
        @transaction_error = transaction_error
      end

      # Formats a failed transaction error
      #
      # @param signature [String] The signature of the transaction
      # @param commitment [String] The commitment the failure was reported at
      # @param transaction_error [Hash, String] The `err` the node reported
      # @return [Solace::Errors::TransactionFailed] The formatted error
      def self.format(signature, commitment, transaction_error)
        new(
          "Transaction #{signature} failed at commitment=#{commitment}: #{transaction_error}",
          signature:         signature,
          commitment:        commitment,
          transaction_error: transaction_error
        )
      end
    end
  end
end

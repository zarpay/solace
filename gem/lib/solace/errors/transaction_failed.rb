# frozen_string_literal: true

module Solace
  module Errors
    # Raised when a transaction being waited on reaches the awaited commitment,
    # and at least "confirmed", with an error. The failure is then part of the
    # ledger, so waiting longer cannot change it.
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
      attr_reader :signature, :commitment, :reported, :transaction_error

      # @param [String] message The error message
      # @param [String] signature The signature of the transaction
      # @param [String] commitment The commitment level awaited
      # @param [String] reported The commitment level the node reported the failure at
      # @param [Hash, String] transaction_error The `err` the node reported
      def initialize(message, signature:, commitment:, reported:, transaction_error:)
        super(message)
        @signature         = signature
        @commitment        = commitment
        @reported          = reported
        @transaction_error = transaction_error
      end

      # Formats a failed transaction error
      #
      # @param signature [String] The signature of the transaction
      # @param commitment [String] The commitment level awaited
      # @param reported [String] The commitment level the node reported the failure at
      # @param transaction_error [Hash, String] The `err` the node reported
      # @return [Solace::Errors::TransactionFailed] The formatted error
      def self.format(signature, commitment, reported, transaction_error)
        new(
          "Transaction #{signature} failed at commitment=#{reported} " \
          "(awaiting #{commitment}): #{transaction_error}",
          signature:         signature,
          commitment:        commitment,
          reported:          reported,
          transaction_error: transaction_error
        )
      end
    end
  end
end

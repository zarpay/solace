# frozen_string_literal: true

module Solace
  module Errors
    # Raised when a transaction confirmation times out.
    #
    # This error is raised when waiting for a transaction to be confirmed by the
    # network exceeds the specified timeout period. This can happen when the
    # network is congested, the transaction fee is too low, or the transaction
    # was not successfully processed by the validators.
    #
    # @example Handling confirmation timeout
    #   begin
    #     connection.wait_for_confirmed_signature(signature, timeout: 30)
    #   rescue Solace::Errors::ConfirmationTimeout => e
    #     puts "Transaction confirmation timed out: #{e.message}"
    #   end
    #
    # @since 0.0.1
    class ConfirmationTimeout < Error
      attr_reader :signature, :commitment, :timeout

      # @param [String] message The error message
      # @param [String] signature The signature of the transaction
      # @param [String] commitment The commitment level not reached
      # @param [Integer] timeout The time out reached
      def initialize(message, signature:, commitment:, timeout:)
        super(message)
        @signature = signature
        @commitment = commitment
        @timeout = timeout
      end

      # Formats a confirmation timeout error
      #
      # @param signature [String] The signature of the transaction
      # @param commitment [String] The commitment level not reached
      # @param timeout [Integer] The time out reached
      # @return [Solace::Errors::ConfirmationTimeout] The formatted error
      def self.format(signature, commitment, timeout)
        new(
          "Timed out waiting for signature #{signature} at commitment=#{commitment} after #{timeout}s",
          signature: signature,
          commitment: commitment,
          timeout: timeout
        )
      end
    end
  end
end

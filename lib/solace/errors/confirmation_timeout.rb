# frozen_string_literal: true

module Solace
  module Errors
    # Waiting for confirmation exceeded timeout
    class ConfirmationTimeout < StandardError
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
      # @params [String] signature The signature of the transaction
      # @params [String] commitment The commitment level not reached
      # @params [Integer] timeout The time out reached
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

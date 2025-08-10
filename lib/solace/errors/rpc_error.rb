# frozen_string_literal: true

module Solace
  module Errors
    # JSON-RPC returned an "error" object
    class RPCError < StandardError
      attr_reader :rpc_code, :rpc_message, :rpc_data

      # @param [String] message The error message
      # @param [Integer] rpc_code The JSON-RPC error code
      # @param [String] rpc_message The JSON-RPC error message
      # @param [Object] rpc_data The JSON-RPC error data
      def initialize(message, rpc_code:, rpc_message:, rpc_data: nil)
        super(message)
        @rpc_code = rpc_code
        @rpc_message = rpc_message
        @rpc_data = rpc_data
      end

      # Formats a response to an error
      #
      # @param response [Hash] The JSON-RPC response
      # @return [Solace::Errors::RPCError] The formatted error
      def self.format_response(response)
        new(
          "RPC error #{response['error']['code']}: #{response['error']['message']}",
          rpc_data: response['error']['data'],
          rpc_code: response['error']['code'],
          rpc_message: response['error']['message']
        )
      end

      # @return [Hash] The error as a hash
      def to_h = { code: rpc_code, message: rpc_message, data: rpc_data }
    end
  end
end

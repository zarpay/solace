# frozen_string_literal: true

module Solace
  module Errors
    # Raised when the RPC node returns an error response.
    #
    # This error is raised when the Solana RPC node successfully processes the HTTP
    # request but returns an error in the JSON-RPC response. This includes errors
    # like invalid parameters, insufficient funds, blockhash not found, and other
    # RPC method-specific errors. The error message and code from the RPC response
    # are included in the exception.
    #
    # @example Handling RPC errors
    #   begin
    #     connection.send_transaction(transaction)
    #   rescue Solace::Errors::RPCError => e
    #     puts "RPC error (code #{e.code}): #{e.message}"
    #   end
    #
    # @see Solace::Errors::HTTPError
    # @since 0.0.1
    class RPCError < ConnectionError
      attr_reader :rpc_code, :rpc_message, :rpc_data

      # @param [String] message The error message
      # @param [Integer] rpc_code The JSON-RPC error code
      # @param [String] rpc_message The JSON-RPC error message
      # @param [Object] rpc_data The JSON-RPC error data
      def initialize(message, rpc_code:, rpc_message:, rpc_data: nil)
        super(message)
        @rpc_code    = rpc_code
        @rpc_message = rpc_message
        @rpc_data    = rpc_data
      end

      # Formats a response to an error
      #
      # @param response [Hash] The JSON-RPC response
      # @return [Solace::Errors::RPCError] The formatted error
      def self.format_response(response)
        new(
          "RPC error #{response['error']['code']}: #{response['error']['message']}",
          rpc_data:    response['error']['data'],
          rpc_code:    response['error']['code'],
          rpc_message: response['error']['message']
        )
      end

      # @return [Hash] The error as a hash
      def to_h = { code: rpc_code, message: rpc_message, data: rpc_data }
    end
  end
end

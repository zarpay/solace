# frozen_string_literal: true

module Solace
  module Errors
    # Raised when parsing or deserializing data fails.
    #
    # This error is raised when the gem encounters data that cannot be properly
    # parsed or deserialized, such as malformed JSON responses from the RPC node,
    # invalid binary data, or unexpected data structures. This typically indicates
    # either a bug in the gem or an incompatibility with the RPC node's response format.
    #
    # @example Handling parse errors
    #   begin
    #     transaction = Solace::Transaction.deserialize(binary_data)
    #   rescue Solace::Errors::ParseError => e
    #     puts "Failed to parse transaction: #{e.message}"
    #   end
    #
    # @since 0.0.1
    class ParseError < Error
      attr_reader :body

      # @param [String] message The error message
      # @param [Object] body The response body
      def initialize(message, body:)
        super(message)
        @body = body
      end

      # Formats a response to an error
      #
      # @param error [JSON::ParserError] The JSON-RPC error
      # @param [Object] response The response from the RPC
      # @return [Solace::Errors::ParseError] The formatted error
      def self.format_response(error, response)
        new("Invalid JSON from RPC: #{error.message}", body: response.body)
      end
    end
  end
end

# frozen_string_literal: true

module Solace
  module Errors
    # JSON parsing failed
    class ParseError < StandardError
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

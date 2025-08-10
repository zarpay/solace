# frozen_string_literal: true

module Solace
  module Errors
    # Non-2xx HTTP or low-level network issues
    class HTTPError < StandardError
      attr_reader :code, :body

      # @param [String] message The error message
      # @param [Integer] code The HTTP status code
      # @param [String] body The HTTP response body
      def initialize(message, code:, body: nil)
        super(message)
        @code = code
        @body = body
      end

      # Formats a response to an error
      #
      # @param response [Net::HTTPResponse] The HTTP response
      # @return [Solace::Errors::HTTPError] The formatted error
      def self.format_response(response)
        new("HTTP error: #{response.message}", code: response.code.to_i, body: response.body)
      end

      # Formats transport errors
      #
      # @param error [SocketError, IOError] The transport error
      # @return [Solace::Errors::HTTPError] The formatted error
      def self.format_transport_error(error)
        new("HTTP transport error: #{error.message}", code: 0)
      end

      # Formats timeout errors
      #
      # @param error [Net::OpenTimeout, Net::ReadTimeout] The timeout error
      # @return [Solace::Errors::HTTPError] The formatted error
      def self.format_timeout_error(error)
        new("HTTP timeout: #{error.class}", code: 408)
      end
    end
  end
end

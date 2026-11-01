# frozen_string_literal: true

require 'time'

module Solace
  module Errors
    # Raised when an HTTP request to the RPC node fails.
    #
    # This error is raised for network-level failures when communicating with the
    # Solana RPC node, including connection timeouts, DNS resolution failures,
    # and HTTP protocol errors. This is distinct from RPC-level errors, which are
    # raised as {Solace::Errors::RPCError}.
    #
    # @example Handling HTTP errors
    #   begin
    #     connection.get_account_info(address)
    #   rescue Solace::Errors::HTTPError => e
    #     puts "Network error: #{e.message}"
    #   end
    #
    # @see Solace::Errors::RPCError
    # @since 0.0.1
    class HTTPError < ConnectionError
      attr_reader :code, :body, :retry_after

      # @param [String] message The error message
      # @param [Integer] code The HTTP status code
      # @param [String] body The HTTP response body
      # @param [Numeric, nil] retry_after Seconds the response's Retry-After asked to wait
      def initialize(message, code:, body: nil, retry_after: nil)
        super(message)
        @code        = code
        @body        = body
        @retry_after = retry_after
      end

      # Formats a response to an error
      #
      # @param response [Net::HTTPResponse] The HTTP response
      # @return [Solace::Errors::HTTPError] The formatted error
      def self.format_response(response)
        new(
          "HTTP error: #{response.message}",
          code:        response.code.to_i,
          body:        response.body,
          retry_after: parse_retry_after(response['Retry-After'])
        )
      end

      # Reads a Retry-After header, given as seconds or as an HTTP date
      #
      # @param value [String, nil] The header's value
      # @return [Float, nil] Seconds to wait, or nil when absent or unreadable
      def self.parse_retry_after(value)
        return if value.nil?
        return Float(value) if value.strip.match?(/\A\d+(\.\d+)?\z/)

        [Time.httpdate(value.strip) - Time.now, 0.0].max
      rescue ArgumentError
        nil
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

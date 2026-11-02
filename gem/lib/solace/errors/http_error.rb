# frozen_string_literal: true

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

      # Formats an answer addressed to a different request
      #
      # @param answered [Object] The id the answer carries
      # @param asked [String] The id of the request that was sent
      # @return [Solace::Errors::HTTPError] The formatted error
      def self.format_mismatched_id(answered, asked)
        new("RPC answer id #{answered.inspect} does not match request id #{asked.inspect}", code: 0)
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

# frozen_string_literal: true

require 'net/http'
require 'json'
require 'uri'

require 'solace/errors'

module Solace
  module Utils
    # RPCClient provides Net::HTTP based HTTP client for sending HTTP requests to a Solana RPC node and parsing responses.
    #
    # @since 0.0.8
    class RPCClient
      # @!attribute [r] url
      #   The URL for the HTTP request
      attr_reader :url

      # @!attribute [r] open_timeout
      #   The timeout for opening an HTTP connection
      attr_reader :open_timeout

      # @!attribute [r] read_timeout
      #   The timeout for reading an HTTP response
      attr_reader :read_timeout

      # Initialize the connection with a default or custom RPC URL
      #
      # @param url [String] The URL of the Solana RPC node
      # @param open_timeout [Integer] The timeout for opening an HTTP connection
      # @param read_timeout [Integer] The timeout for reading an HTTP response
      def initialize(
        url,
        open_timeout:,
        read_timeout:
      )
        @url = url
        @open_timeout = open_timeout
        @read_timeout = read_timeout
      end

      # Sends a JSON-RPC request to the configured Solana RPC server.
      #
      # @param method [String] the JSON-RPC method name
      # @param params [Array] the parameters for the RPC method
      # @return [Hash] the parsed JSON response
      # @raise [
      #   Solace::Errors::HTTPError,
      #   Solace::Errors::ParseError,
      #   Solace::Errors::RPCError,
      #   Solace::Errors::ConfirmationTimeout
      # ]
      def rpc_request(method, params = [])
        request = build_rpc_request(method, params)
        response = perform_http_request(request)
        handle_rpc_response(response)
      end

      private

      # Builds a JSON-RPC request
      #
      # @param method [String] the JSON-RPC method name
      # @param params [Array] the parameters for the RPC method
      # @return [Array] the URI and request object
      def build_rpc_request(method, params)
        uri = URI(url)

        req = Net::HTTP::Post.new(uri)
        req['Accept'] = 'application/json'
        req['Content-Type'] = 'application/json'
        req.body = build_request_body(method, params)

        [uri, req]
      end

      # Builds request body
      #
      # @param method [String] the JSON-RPC method name
      # @param params [Array] the parameters for the RPC method
      # @return [String] the request body
      def build_request_body(method, params)
        {
          jsonrpc: '2.0',
          id: SecureRandom.uuid,
          method: method,
          params: params
        }.to_json
      end

      # Performs an HTTP request to the configured Solana RPC server.
      #
      # @param (uri, req) [Array] the URI and request object
      # @return [Net::HTTPResponse] the HTTP response
      # @raise [Solace::Errors::HTTPError]
      def perform_http_request((uri, req))
        Net::HTTP.start(
          uri.hostname,
          uri.port,
          use_ssl: uri.scheme == 'https',
          open_timeout: open_timeout,
          read_timeout: read_timeout
        ) do |http|
          http.request(req)
        end
      rescue Net::OpenTimeout, Net::ReadTimeout => e
        raise Errors::HTTPError.format_timeout_error(e)
      rescue SocketError, IOError => e
        raise Errors::HTTPError.format_transport_error(e)
      end

      # Handles the response from the HTTP request
      #
      # @param response [Net::HTTPResponse] The HTTP response
      # @return [Hash] The parsed JSON response
      # @raise [Solace::Errors::HTTPError]
      # @raise [Solace::Errors::ParseError]
      # @raise [Solace::Errors::RPCError]
      def handle_rpc_response(response)
        raise Errors::HTTPError.format_response(response) unless response.is_a?(Net::HTTPSuccess)

        json = JSON.parse(response.body)

        raise Errors::RPCError.format_response(json) if json['error']

        json
      rescue JSON::ParserError => e
        raise Errors::ParseError.format_response(e, response)
      end
    end
  end
end

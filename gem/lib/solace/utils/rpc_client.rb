# frozen_string_literal: true

require 'net/http'
require 'json'
require 'securerandom'
require 'uri'

require 'solace/errors'
require 'solace/utils/http_connections'

module Solace
  module Utils
    # RPCClient provides Net::HTTP based HTTP client for sending HTTP
    # requests to a Solana RPC node and parsing responses. Each call opens and
    # closes its own connection unless the client opts into sharing them
    # through {HTTPConnections}.
    #
    # @since 0.0.8
    class RPCClient
      # Methods a reused connection must not send twice. Every other method is a
      # read, or a sendTransaction the cluster will not execute twice.
      UNREPEATABLE_METHODS = %w[requestAirdrop].freeze

      # @!attribute [r] url
      #   The URL for the HTTP request
      attr_reader :url

      # @!attribute [r] open_timeout
      #   The timeout for opening an HTTP connection
      attr_reader :open_timeout

      # @!attribute [r] read_timeout
      #   The timeout for reading an HTTP response
      attr_reader :read_timeout

      # @!attribute [r] reuse_connections
      #   Whether calls reuse open connections through {HTTPConnections}
      attr_reader :reuse_connections

      # Initialize the connection with a default or custom RPC URL
      #
      # @param url [String] The URL of the Solana RPC node
      # @param open_timeout [Integer] The timeout for opening an HTTP connection
      # @param read_timeout [Integer] The timeout for reading an HTTP response
      # @param reuse_connections [Boolean] Whether calls reuse open connections
      #   through {HTTPConnections}, and refuse an answer carrying another
      #   request's id
      def initialize(
        url,
        open_timeout:,
        read_timeout:,
        reuse_connections: false
      )
        @url               = url
        @open_timeout      = open_timeout
        @read_timeout      = read_timeout
        @reuse_connections = reuse_connections
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
        id       = SecureRandom.uuid
        request  = build_rpc_request(method, params, id)
        response = perform_http_request(*request, repeatable: !UNREPEATABLE_METHODS.include?(method))
        handle_rpc_response(response, id)
      end

      private

      # Builds a JSON-RPC request
      #
      # @param method [String] the JSON-RPC method name
      # @param params [Array] the parameters for the RPC method
      # @param id [String] the JSON-RPC request id
      # @return [Array] the URI and request object
      def build_rpc_request(method, params, id)
        uri = URI(url)

        req                 = Net::HTTP::Post.new(uri)
        req['Accept']       = 'application/json'
        req['Content-Type'] = 'application/json'
        req.body            = build_request_body(method, params, id)

        [uri, req]
      end

      # Builds request body
      #
      # @param method [String] the JSON-RPC method name
      # @param params [Array] the parameters for the RPC method
      # @param id [String] the JSON-RPC request id
      # @return [String] the request body
      def build_request_body(method, params, id)
        {
          jsonrpc: '2.0',
          id:      id,
          method:  method,
          params:  params
        }.to_json
      end

      # Performs an HTTP request to the configured Solana RPC server.
      #
      # @param uri [URI] the URI for the HTTP request
      # @param req [Net::HTTP::Post] the request object
      # @param repeatable [Boolean] whether a reused connection may send it twice
      # @return [Net::HTTPResponse] the HTTP response
      # @raise [Solace::Errors::HTTPError]
      def perform_http_request(uri, req, repeatable:)
        if reuse_connections
          HTTPConnections.request(uri, req, open_timeout: open_timeout, read_timeout: read_timeout,
repeatable: repeatable)
        else
          request_once(uri, req)
        end
      rescue Net::OpenTimeout, Net::ReadTimeout => e
        raise Errors::HTTPError.format_timeout_error(e)
      rescue SocketError, IOError => e
        raise Errors::HTTPError.format_transport_error(e)
      end

      # Sends a request over a connection opened for it and closed after it.
      #
      # @param uri [URI] the URI for the HTTP request
      # @param req [Net::HTTP::Post] the request object
      # @return [Net::HTTPResponse] the HTTP response
      def request_once(uri, req)
        Net::HTTP.start(
          uri.hostname,
          uri.port,
          use_ssl:      uri.scheme == 'https',
          open_timeout: open_timeout,
          read_timeout: read_timeout
        ) { |http| http.request(req) }
      end

      # Handles the response from the HTTP request
      #
      # @param response [Net::HTTPResponse] The HTTP response
      # @param id [String] The JSON-RPC request id
      # @return [Hash] The parsed JSON response
      # @raise [Solace::Errors::HTTPError]
      # @raise [Solace::Errors::ParseError]
      # @raise [Solace::Errors::RPCError]
      def handle_rpc_response(response, id)
        raise Errors::HTTPError.format_response(response) unless response.is_a?(Net::HTTPSuccess)

        json = JSON.parse(response.body)

        ensure_answers!(json, id) if reuse_connections

        raise Errors::RPCError.format_response(json) if json['error']

        json
      rescue JSON::ParserError => e
        raise Errors::ParseError.format_response(e, response)
      end

      # An answer must carry the id of the request it answers; only an error the
      # node could not tie to a request may carry none. Any other id means the
      # answer belongs to another call, and is refused rather than returned.
      # Only clients that reuse connections check: a socket shared across calls
      # is what could hand one call another's answer.
      #
      # @param json [Hash] The parsed JSON response
      # @param id [String] The JSON-RPC request id
      # @raise [Solace::Errors::HTTPError]
      def ensure_answers!(json, id)
        return if json['id'] == id || (json['id'].nil? && json['error'])

        raise Errors::HTTPError.format_mismatched_id(json['id'], id)
      end
    end
  end
end

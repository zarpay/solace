# frozen_string_literal: true

module Solace
  module Errors
    # Base error class for connection-related failures.
    #
    # Both {Solace::Errors::HTTPError} and {Solace::Errors::RPCError} inherit
    # from this class, allowing consumers to rescue all connection errors with
    # a single clause:
    #
    # @example Rescuing all connection errors
    #   begin
    #     connection.send_transaction(transaction)
    #   rescue Solace::Errors::ConnectionError => e
    #     puts "Connection error: #{e.message}"
    #   end
    #
    # @see Solace::Errors::HTTPError
    # @see Solace::Errors::RPCError
    # @since 0.1.0
    class ConnectionError < Error; end
  end
end

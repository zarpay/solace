# frozen_string_literal: true

module Solace
  # The Errors module contains custom exception classes for the Solace gem.
  #
  # These exceptions provide specific error handling for various failure scenarios
  # when interacting with the Solana blockchain, including:
  # - {Solace::Errors::HTTPError} - HTTP communication failures
  # - {Solace::Errors::RPCError} - RPC method errors returned by the node
  # - {Solace::Errors::ParseError} - Data parsing and deserialization errors
  # - {Solace::Errors::ConfirmationTimeout} - Transaction confirmation timeouts
  #
  # @see Solace::Connection
  # @since 0.0.8
  module Errors
    # JSON-RPC Errors
    require 'solace/errors/rpc_error'
    require 'solace/errors/http_error'
    require 'solace/errors/parse_error'
    require 'solace/errors/confirmation_timeout'
  end
end

# frozen_string_literal: true

module Solace
  # Error handling module
  #
  # This module provides error classes for handling different types of errors that may occur during
  # Solana RPC requests and processing transactions.
  #
  # @since 0.0.8
  module Errors
    # JSON-RPC Errors
    require 'solace/errors/rpc_error'
    require 'solace/errors/http_error'
    require 'solace/errors/parse_error'
    require 'solace/errors/confirmation_timeout'
  end
end

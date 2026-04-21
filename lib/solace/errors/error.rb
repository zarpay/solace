# frozen_string_literal: true

module Solace
  module Errors
    # Base error class for all Solace errors.
    #
    # All Solace-specific exceptions inherit from this class, allowing consumers
    # to rescue all Solace errors with a single clause:
    #
    # @example Rescuing all Solace errors
    #   begin
    #     connection.get_account_info(address)
    #   rescue Solace::Errors::Error => e
    #     puts "Solace error: #{e.message}"
    #   end
    #
    # @since 0.1.0
    class Error < StandardError; end
  end
end

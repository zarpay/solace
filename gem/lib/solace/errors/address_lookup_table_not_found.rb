# frozen_string_literal: true

module Solace
  module Errors
    # Raised when an address lookup table a transaction references does not
    # exist on chain. A message that loads addresses through a table cannot be
    # taken apart without the table's address list, so a missing table is an
    # error rather than an empty list.
    #
    # @example
    #   begin
    #     Solace::TransactionComposer.from(transaction, connection: connection)
    #   rescue Solace::Errors::AddressLookupTableNotFound => e
    #     puts "missing table: #{e.account}"
    #   end
    #
    # @since 0.1.9
    class AddressLookupTableNotFound < Error
      # @return [String] The lookup table's on-chain address
      attr_reader :account

      # @param account [String] The lookup table's on-chain address
      def initialize(account)
        super("address lookup table #{account} not found on chain")
        @account = account
      end
    end
  end
end

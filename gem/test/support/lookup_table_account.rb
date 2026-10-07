# frozen_string_literal: true

# Test helper that builds the getAccountInfo answer for an address lookup
# table holding the given addresses: the 56-byte metadata region, then the
# addresses as raw 32-byte pubkeys. For stubbing a connection where a real
# table is not needed (see LookupTableProvisioner for one that is).
module LookupTableAccount
  extend self

  # @param addresses [Array<#to_s>] The addresses the table holds
  # @return [Hash] The account info the RPC would answer
  def info(addresses)
    meta  = [0] * Solace::Accounts::AddressLookupTable::META_SIZE
    bytes = meta + addresses.flat_map { |address| Solace::Utils::Codecs.base58_to_bytes(address.to_s) }

    { 'data' => [Base64.strict_encode64(bytes.pack('C*')), 'base64'] }
  end

  # Stub a connection to answer the given tables and nothing else
  #
  # @param connection [Solace::Connection] The connection to stub
  # @param tables [Hash{String => Array<String>}] Table account => addresses
  # @return [Array<String>] The accounts fetched, appended to as the stub is called
  def stub(connection, tables)
    fetched = []

    stubbed = connection.singleton_methods.include?(:get_account_info)

    connection.singleton_class.remove_method(:get_account_info) if stubbed
    connection.define_singleton_method(:get_account_info) do |account|
      fetched << account
      tables.key?(account) ? LookupTableAccount.info(tables[account]) : nil
    end

    fetched
  end
end

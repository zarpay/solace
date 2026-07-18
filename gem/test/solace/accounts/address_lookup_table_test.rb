# frozen_string_literal: true

require 'test_helper'
require 'stringio'

describe Solace::Accounts::AddressLookupTable do
  let(:authority) { Solace::Keypair.generate.address }
  let(:address1) { Solace::Keypair.generate.address }
  let(:address2) { Solace::Keypair.generate.address }
  let(:address3) { Solace::Keypair.generate.address }

  # Build the raw bytes of an on-chain lookup table account
  def encode_account_data(authority:, addresses:, deactivation_slot: (2**64) - 1, last_extended_slot: 42)
    meta  = encode_meta(authority, deactivation_slot, last_extended_slot)
    addrs = addresses.flat_map { |address| Solace::Utils::Codecs.base58_to_bytes(address) }

    StringIO.new((meta + addrs).pack('C*'))
  end

  # The fixed-size metadata region preceding the stored addresses
  def encode_meta(authority, deactivation_slot, last_extended_slot)
    codecs = Solace::Utils::Codecs
    bytes  = codecs.encode_le_u32(1).bytes + # state type = LookupTable
             codecs.encode_le_u64(deactivation_slot).bytes +
             codecs.encode_le_u64(last_extended_slot).bytes +
             [0] + # last extended start index
             codecs.encode_option_pubkey(authority)

    bytes + ([0] * (Solace::Accounts::AddressLookupTable::META_SIZE - bytes.length))
  end

  describe '.deserialize' do
    it 'reads the metadata and stored addresses' do
      io    = encode_account_data(authority: authority, addresses: [address1, address2], last_extended_slot: 99)
      table = Solace::Accounts::AddressLookupTable.deserialize(io)

      assert_equal authority, table.authority
      assert_equal 99, table.last_extended_slot
      assert_equal (2**64) - 1, table.deactivation_slot
      assert_equal [address1, address2], table.addresses
    end

    it 'reads a freshly created table that has no addresses yet' do
      table = Solace::Accounts::AddressLookupTable.deserialize(
        encode_account_data(authority: authority, addresses: [])
      )

      assert_equal authority, table.authority
      assert_empty table.addresses
    end

    it 'handles a table with no authority' do
      table = Solace::Accounts::AddressLookupTable.deserialize(
        encode_account_data(authority: nil, addresses: [address1])
      )

      assert_nil table.authority
      assert_equal [address1], table.addresses
    end
  end

  describe '#reference' do
    let(:table_account) { Solace::Keypair.generate.address }

    let(:table) do
      Solace::Accounts::AddressLookupTable.new(account: table_account, addresses: [address1, address2, address3])
    end

    it 'builds a message reference from the loaded addresses' do
      reference = table.reference([address2], [address1])

      assert_instance_of Solace::AddressLookupTable, reference
      assert_equal table_account, reference.account
      assert_equal [1], reference.writable_indexes # address2
      assert_equal [0], reference.readonly_indexes # address1
    end

    it 'emits the index positions in the order given' do
      reference = table.reference([address3, address1], [])

      assert_equal [2, 0], reference.writable_indexes
    end

    it 'returns nil when the table contributes no loaded accounts' do
      assert_nil table.reference([], [])
    end
  end

  describe '#initialize' do
    it 'normalizes the account and addresses to strings' do
      keypair = Solace::Keypair.generate

      table = Solace::Accounts::AddressLookupTable.new(account: keypair, addresses: [keypair])

      assert_equal keypair.address, table.account
      assert_equal [keypair.address], table.addresses
    end

    it 'defaults to an empty address list' do
      table = Solace::Accounts::AddressLookupTable.new(account: authority)

      assert_empty table.addresses
    end
  end
end

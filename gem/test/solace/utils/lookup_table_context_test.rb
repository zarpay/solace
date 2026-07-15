# frozen_string_literal: true

require 'test_helper'

describe Solace::Utils::LookupTableContext do
  let(:lookup_tables) { Solace::Utils::LookupTableContext.new }

  let(:table_account) { Solace::Keypair.generate.address }

  let(:fee_payer) { Solace::Keypair.generate.address }
  let(:signer) { Solace::Keypair.generate.address }
  let(:writable) { Solace::Keypair.generate.address }
  let(:readonly) { Solace::Keypair.generate.address }
  let(:unrelated) { Solace::Keypair.generate.address }
  let(:program_id) { Solace::Constants::TOKEN_PROGRAM_ID }

  let(:account_context) do
    Solace::Utils::AccountContext.new.tap do |context|
      context.set_fee_payer(fee_payer)
      context.add_writable_signer(signer)
      context.add_writable_nonsigner(writable)
      context.add_readonly_nonsigner(readonly)
      context.add_readonly_nonsigner(program_id)

      context.compile
    end
  end

  describe '#initialize' do
    it 'starts with no tables' do
      assert_empty lookup_tables.tables
      assert lookup_tables.empty?
    end
  end

  describe '#add_table' do
    it 'registers a table and returns self for chaining' do
      result = lookup_tables.add_table(account: table_account, addresses: [writable])

      assert_equal lookup_tables, result
      assert_equal [{ account: table_account, addresses: [writable] }], lookup_tables.tables
      refute lookup_tables.empty?
    end

    it 'normalizes accounts and addresses to strings' do
      keypair = Solace::Keypair.generate

      lookup_tables.add_table(account: keypair, addresses: [keypair])

      assert_equal [{ account: keypair.address, addresses: [keypair.address] }], lookup_tables.tables
    end
  end

  describe '#select_loaded_accounts' do
    before do
      lookup_tables.add_table(
        account:   table_account,
        addresses: [unrelated, writable, readonly, signer, fee_payer, program_id]
      )
    end

    it 'splits loadable accounts into writable and readonly segments with table references' do
      writable_segment, readonly_segment = lookup_tables.select_loaded_accounts(account_context, [program_id])

      assert_equal({ writable => { table_index: 0, address_index: 1 } }, writable_segment)
      assert_equal({ readonly => { table_index: 0, address_index: 2 } }, readonly_segment)
    end

    it 'never loads signers, the fee payer, program ids, or unreferenced addresses' do
      writable_segment, readonly_segment = lookup_tables.select_loaded_accounts(account_context, [program_id])

      loaded = writable_segment.keys + readonly_segment.keys

      assert_empty loaded & [signer, fee_payer, program_id, unrelated]
    end

    it 'chooses the first table when tables share an address' do
      other_table = Solace::Keypair.generate.address
      lookup_tables.add_table(account: other_table, addresses: [writable, readonly])

      writable_segment, = lookup_tables.select_loaded_accounts(account_context, [program_id])

      assert_equal({ table_index: 0, address_index: 1 }, writable_segment[writable])
    end

    it 'returns empty segments when nothing is loadable' do
      other_context = Solace::Utils::AccountContext.new.tap do |context|
        context.set_fee_payer(fee_payer)
        context.compile
      end

      assert_equal [{}, {}], lookup_tables.select_loaded_accounts(other_context, [])
    end
  end

  describe '#address_lookup_tables_for' do
    let(:other_table) { Solace::Keypair.generate.address }

    before do
      lookup_tables.add_table(account: table_account, addresses: [unrelated, writable])
      lookup_tables.add_table(account: other_table, addresses: [readonly])
    end

    it 'builds one reference per contributing table' do
      references = lookup_tables.address_lookup_tables_for(
        { writable => { table_index: 0, address_index: 1 } },
        { readonly => { table_index: 1, address_index: 0 } }
      )

      assert_equal 2, references.length
      assert_instance_of Solace::AddressLookupTable, references.first

      assert_equal table_account, references.first.account
      assert_equal [1], references.first.writable_indexes
      assert_empty references.first.readonly_indexes

      assert_equal other_table, references.last.account
      assert_empty references.last.writable_indexes
      assert_equal [0], references.last.readonly_indexes
    end

    it 'omits tables that contribute no loaded accounts' do
      references = lookup_tables.address_lookup_tables_for(
        { writable => { table_index: 0, address_index: 1 } },
        {}
      )

      assert_equal [table_account], references.map(&:account)
    end
  end
end

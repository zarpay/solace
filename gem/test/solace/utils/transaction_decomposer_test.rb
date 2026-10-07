# frozen_string_literal: true

require 'test_helper'

describe Solace::Utils::TransactionDecomposer do
  let(:connection) { Solace::Connection.new }
  let(:keys) { Array.new(8) { Solace::Keypair.generate.address } }
  let(:blockhash) { 'EkSnNWid2cvwEVnVx9aBqawnmiCNiDgp3gUdkDPTKN1N' }
  let(:compute_budget_program) { Solace::Constants::COMPUTE_BUDGET_PROGRAM_ID }

  def instruction(program_index, accounts, data)
    Solace::Instruction.new.tap do |ix|
      ix.program_index = program_index
      ix.accounts      = accounts
      ix.data          = data
    end
  end

  def reference(account, writable, readonly)
    Solace::AddressLookupTable.new.tap do |ref|
      ref.account          = account
      ref.writable_indexes = writable
      ref.readonly_indexes = readonly
    end
  end

  def metas(composer)
    composer.accounts.map { |meta| [meta[:pubkey], meta[:signer], meta[:writable]] }
  end

  describe 'a legacy message' do
    # header [3, 1, 2]: payer, cosigner (writable signers), readonly signer,
    # destination (writable), mint and program (readonly)
    let(:compiled) do
      Solace::Message.new(
        header:           [3, 1, 2],
        accounts:         keys.first(6),
        instructions:     [instruction(5, [0, 1, 2, 3, 4], [7, 7])],
        recent_blockhash: blockhash
      )
    end

    let(:parts) { Solace::Utils::TransactionDecomposer.new(compiled, connection: connection) }

    it 'answers the fee payer and blockhash' do
      assert_equal keys[0], parts.fee_payer
      assert_equal blockhash, parts.blockhash
    end

    it 'lifts each account with the flags its header position gives it' do
      composer = parts.instruction_composers.first

      assert_equal 1, parts.instruction_composers.length
      assert_equal keys[5], composer.program_id
      assert_equal [7, 7], composer.data
      assert_equal(
        [
          [keys[0], true, true],
          [keys[1], true, true],
          [keys[2], true, false],
          [keys[3], false, true],
          [keys[4], false, false]
        ],
        metas(composer)
      )
    end

    it 'seeds a context holding the static keys in message order' do
      context = parts.account_context

      assert_equal keys.first(6), context.pubkey_account_map.keys
      assert context.signer?(keys[2])
      refute context.writable?(keys[2])
      refute context.signer?(keys[3])
      assert context.writable?(keys[3])
    end

    it 'carries no budget and no tables' do
      refute_predicate parts.compute_budget, :set?
      assert_empty parts.lookup_tables
    end
  end

  describe 'a v0 message loading through two tables' do
    let(:first_table) { Solace::Keypair.generate.address }
    let(:second_table) { Solace::Keypair.generate.address }
    let(:first_entries) { Array.new(3) { Solace::Keypair.generate.address } }
    let(:second_entries) { Array.new(3) { Solace::Keypair.generate.address } }

    # statics: payer, vault, program; combined space:
    # [payer, vault, program, first[1], second[2], first[0], second[0]]
    let(:compiled) do
      Solace::Message.new(
        version:               0,
        header:                [1, 0, 1],
        accounts:              keys.first(3),
        instructions:          [instruction(2, [1, 3, 4, 5, 6], [1])],
        recent_blockhash:      blockhash,
        address_lookup_tables: [reference(first_table, [1], [0]), reference(second_table, [2], [0])]
      )
    end

    let(:parts) { Solace::Utils::TransactionDecomposer.new(compiled, connection: connection) }

    before do
      @fetched = LookupTableAccount.stub(connection, first_table => first_entries, second_table => second_entries)
    end

    it 'resolves the combined space writable segment first and lets no loaded account sign' do
      assert_equal keys.first(3) + [first_entries[1], second_entries[2], first_entries[0], second_entries[0]], parts.accounts
      assert_equal(
        [
          [keys[1], false, true],
          [first_entries[1], false, true],
          [second_entries[2], false, true],
          [first_entries[0], false, false],
          [second_entries[0], false, false]
        ],
        metas(parts.instruction_composers.first)
      )
    end

    it 'hands the tables on whole, fetched once each' do
      parts.instruction_composers
      tables = parts.lookup_tables

      assert_equal [first_table, second_table], tables.map(&:account)
      assert_equal [first_entries, second_entries], tables.map(&:addresses)
      assert_equal [first_table, second_table], @fetched
    end

    it 'refuses a table the chain does not hold' do
      LookupTableAccount.stub(connection, first_table => first_entries)

      error = assert_raises(Solace::Errors::AddressLookupTableNotFound) { parts.accounts }

      assert_equal second_table, error.account
      assert_match(/#{second_table}/, error.message)
    end
  end

  describe 'a message carrying a compute budget' do
    let(:limit_data) { [2] + [200_000].pack('L<').bytes }
    let(:price_data) { [3] + [50_000].pack('Q<').bytes }
    let(:other_data) { [4, 0, 0, 1, 0] }

    let(:compiled) do
      Solace::Message.new(
        header:           [1, 0, 2],
        accounts:         [keys[0], keys[1], compute_budget_program, Solace::Constants::SYSTEM_PROGRAM_ID],
        instructions:     [
          instruction(2, [], limit_data),
          instruction(2, [], price_data),
          instruction(2, [], other_data),
          instruction(3, [0, 1], [2, 0, 0, 0] + [1_000].pack('Q<').bytes)
        ],
        recent_blockhash: blockhash
      )
    end

    let(:parts) { Solace::Utils::TransactionDecomposer.new(compiled, connection: connection) }

    it 'decodes the limit and price into the budget' do
      assert_equal 200_000, parts.compute_budget.units
      assert_equal 50_000, parts.compute_budget.micro_lamports
    end

    it 'leaves the budget directives out of the composers and keeps any other directive generic' do
      composers = parts.instruction_composers

      assert_equal [compute_budget_program, Solace::Constants::SYSTEM_PROGRAM_ID], composers.map(&:program_id)
      assert_equal other_data, composers.first.data
      assert_empty composers.first.accounts
    end
  end
end

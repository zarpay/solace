# frozen_string_literal: true

require 'test_helper'

describe Solace::TransactionDecomposer do
  let(:connection) { Solace::Connection.new }
  let(:decomposer) { Solace::TransactionDecomposer.new(connection: connection) }
  let(:composer) { Solace::TransactionComposer.new(connection: connection) }

  let(:random_keypair) { Solace::Keypair.generate }
  let(:bob_keypair) { Fixtures.load_keypair('bob') }
  let(:anna_keypair) { Fixtures.load_keypair('anna') }
  let(:payer_keypair) { Fixtures.load_keypair('payer') }
  let(:system_program) { Solace::Constants::SYSTEM_PROGRAM_ID }
  let(:compute_budget_program) { Solace::Constants::COMPUTE_BUDGET_PROGRAM_ID }

  let(:transfer_composer1) do
    Solace::Composers::SystemProgramTransferComposer.new(from: anna_keypair, to: bob_keypair, lamports: 1000)
  end

  let(:transfer_composer2) do
    Solace::Composers::SystemProgramTransferComposer.new(from: bob_keypair, to: random_keypair, lamports: 500)
  end

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

  def metas(instruction_composer)
    instruction_composer.accounts.map { |meta| [meta[:pubkey], meta[:signer], meta[:writable]] }
  end

  describe 'reading a hand-built message' do
    let(:keys) { Array.new(8) { Solace::Keypair.generate.address } }
    let(:blockhash) { 'EkSnNWid2cvwEVnVx9aBqawnmiCNiDgp3gUdkDPTKN1N' }

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

      let(:recovered) { decomposer.decompose_transaction(compiled) }

      it 'answers a composer with the fee payer, blockhash and static keys in message order' do
        assert_equal blockhash, recovered.blockhash
        assert recovered.context.fee_payer?(keys[0])
        assert_equal keys.first(6), recovered.context.pubkey_account_map.keys
        assert_nil recovered.version
        refute_predicate recovered.compute_budget, :set?
        assert_empty recovered.address_lookup_tables
      end

      it 'lifts each account with the flags its header position gives it' do
        lifted = recovered.instruction_composers.first

        assert_equal 1, recovered.instruction_composers.length
        assert_kind_of Solace::Composers::OpaqueInstructionComposer, lifted
        assert_equal keys[5], lifted.program_id
        assert_equal [7, 7], lifted.data
        assert_equal(
          [
            [keys[0], true, true],
            [keys[1], true, true],
            [keys[2], true, false],
            [keys[3], false, true],
            [keys[4], false, false]
          ],
          metas(lifted)
        )
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

      before do
        @fetched = LookupTableAccount.stub(connection, first_table => first_entries, second_table => second_entries)
      end

      it 'resolves the combined space writable segment first and lets no loaded account sign' do
        lifted = decomposer.decompose_transaction(compiled).instruction_composers.first

        assert_equal(
          [
            [keys[1], false, true],
            [first_entries[1], false, true],
            [second_entries[2], false, true],
            [first_entries[0], false, false],
            [second_entries[0], false, false]
          ],
          metas(lifted)
        )
      end

      it 'registers the tables whole, fetched once each, and composes as v0' do
        recovered = decomposer.decompose_transaction(compiled)

        assert_equal 0, recovered.version
        assert_equal [first_table, second_table], recovered.address_lookup_tables.map(&:account)
        assert_equal [first_entries, second_entries], recovered.address_lookup_tables.map(&:addresses)
        assert_equal [first_table, second_table], @fetched
      end

      it 'refuses a table the chain does not hold' do
        LookupTableAccount.stub(connection, first_table => first_entries)

        error = assert_raises(Solace::Errors::AddressLookupTableNotFound) { decomposer.decompose_transaction(compiled) }

        assert_equal second_table, error.account
        assert_match(/#{second_table}/, error.message)
      end
    end

    describe 'a message carrying compute budget directives' do
      let(:limit_data) { [2] + [200_000].pack('L<').bytes }
      let(:price_data) { [3] + [50_000].pack('Q<').bytes }
      let(:other_data) { [4, 0, 0, 1, 0] }

      let(:compiled) do
        Solace::Message.new(
          header:           [1, 0, 2],
          accounts:         [keys[0], keys[1], compute_budget_program, system_program],
          instructions:     [
            instruction(2, [], limit_data),
            instruction(2, [], price_data),
            instruction(2, [], other_data),
            instruction(3, [0, 1], [2, 0, 0, 0] + [1_000].pack('Q<').bytes)
          ],
          recent_blockhash: blockhash
        )
      end

      let(:recovered) { decomposer.decompose_transaction(compiled) }

      it 'decodes the limit and price into the budget' do
        assert_equal 200_000, recovered.compute_budget.units
        assert_equal 50_000, recovered.compute_budget.micro_lamports
      end

      it 'leaves the budget directives out of the composers and keeps any other directive generic' do
        lifted = recovered.instruction_composers

        assert_equal [compute_budget_program, system_program], lifted.map(&:program_id)
        assert_equal other_data, lifted.first.data
        assert_empty lifted.first.accounts
      end
    end
  end

  describe '#decompose_transaction' do
    let(:blockhash) { 'EkSnNWid2cvwEVnVx9aBqawnmiCNiDgp3gUdkDPTKN1N' }
    let(:table_account) { Solace::Keypair.generate.address }
    let(:loaded_recipient) { Solace::Keypair.generate.address }

    before do
      def connection.get_latest_blockhash
        ['EkSnNWid2cvwEVnVx9aBqawnmiCNiDgp3gUdkDPTKN1N', 1000]
      end

      LookupTableAccount.stub(connection, table_account => [random_keypair.address, loaded_recipient])
    end

    # Compose, take apart, compose again; answer both transactions
    def round_trip(composer)
      original  = composer.compose_transaction
      recovered = decomposer.decompose_transaction(original)

      [original, recovered.compose_transaction]
    end

    describe 'a legacy transaction' do
      before do
        composer.add_instruction(transfer_composer1).add_instruction(transfer_composer2).set_fee_payer(payer_keypair)
      end

      it 'answers one instruction composer per instruction with the flags the header gave them' do
        recovered = decomposer.decompose_transaction(composer.compose_transaction)
        first     = recovered.instruction_composers.first

        assert_equal 2, recovered.instruction_composers.length
        assert_kind_of Solace::Composers::OpaqueInstructionComposer, first
        assert_equal system_program, first.program_id
        assert_equal(
          [{ pubkey: anna_keypair.address, signer: true, writable: true }, { pubkey: bob_keypair.address, signer: true, writable: true }],
          first.accounts
        )
        assert recovered.context.fee_payer?(payer_keypair.address)
        assert_nil recovered.version
        refute_predicate recovered.compute_budget, :set?
      end

      it 'accepts the transaction or its base64 alike' do
        transaction = composer.compose_transaction

        assert_equal(
          decomposer.decompose_transaction(transaction).compose_transaction.serialize,
          decomposer.decompose_transaction(transaction.serialize).compose_transaction.serialize
        )
      end

      it 'composes it again byte for byte' do
        original, recomposed = round_trip(composer)

        assert_equal original.serialize, recomposed.serialize
      end

      it 'defaults to the blockhash it was recovered with, without fetching' do
        transaction = composer.compose_transaction
        connection.singleton_class.remove_method(:get_latest_blockhash)
        connection.define_singleton_method(:get_latest_blockhash) { raise 'should not fetch' }

        recovered = decomposer.decompose_transaction(transaction)

        assert_equal blockhash, recovered.blockhash
        assert_equal blockhash, recovered.compose_transaction.message.recent_blockhash
      end

      it 'still honours an explicit blockhash' do
        other     = '4vJ9JU1bJJE96FWSJKvHsmmFADCg4gpZQff4P3bkLKi'
        recovered = decomposer.decompose_transaction(composer.compose_transaction)

        assert_equal other, recovered.compose_transaction(blockhash: other).message.recent_blockhash
      end

      it 'can be edited like any composer' do
        recovered = decomposer.decompose_transaction(composer.compose_transaction)
        extra     = Solace::Composers::SystemProgramTransferComposer.new(from: bob_keypair, to: anna_keypair, lamports: 5)

        message = recovered.add_instruction(extra)
                           .set_compute_budget(units: 300_000)
                           .compose_transaction.message

        assert_equal payer_keypair.address, message.accounts[0]
        assert_equal 4, message.instructions.length
        assert_equal Solace::Constants::COMPUTE_BUDGET_PROGRAM_ID, message.accounts[message.instructions.first.program_index]
      end
    end

    describe 'a transaction carrying a compute budget' do
      before do
        composer.add_instruction(transfer_composer1).set_fee_payer(payer_keypair)
                .set_compute_budget(units: 200_000, micro_lamports: 50_000)
      end

      it 'recovers the budget as the setting, leaving it out of the instruction composers' do
        recovered = decomposer.decompose_transaction(composer.compose_transaction)

        assert_equal 200_000, recovered.compute_budget.units
        assert_equal 50_000, recovered.compute_budget.micro_lamports
        assert_equal [system_program], recovered.instruction_composers.map(&:program_id)
      end

      it 'composes it again byte for byte, and resized when asked' do
        original, recomposed = round_trip(composer)

        assert_equal original.serialize, recomposed.serialize

        resized = decomposer.decompose_transaction(original)
                            .set_compute_budget(units: 400_000, micro_lamports: 50_000)
                            .compose_transaction.message

        assert_equal [2] + [400_000].pack('L<').bytes, resized.instructions.first.data
      end
    end

    describe 'a v0 transaction' do
      let(:loaded_transfer) do
        Solace::Composers::SystemProgramTransferComposer.new(from: anna_keypair, to: loaded_recipient, lamports: 10)
      end

      before do
        composer.add_instruction(loaded_transfer).add_instruction(transfer_composer1).set_fee_payer(payer_keypair)
                .add_address_lookup_table(account: table_account, addresses: [random_keypair.address, loaded_recipient])
      end

      it 'registers the table from chain and resolves the loaded account with its flags' do
        recovered = decomposer.decompose_transaction(composer.compose_transaction)
        first     = recovered.instruction_composers.first

        assert_equal 0, recovered.version
        assert_equal [table_account], recovered.address_lookup_tables.map(&:account)
        assert_equal [random_keypair.address, loaded_recipient], recovered.address_lookup_tables.first.addresses
        assert_equal({ pubkey: loaded_recipient, signer: false, writable: true }, first.accounts[1])
      end

      it 'composes it again byte for byte' do
        original, recomposed = round_trip(composer)

        refute_includes original.message.accounts, loaded_recipient
        assert_equal original.serialize, recomposed.serialize
      end
    end
  end

  describe 'recomposing a v0 transaction taken apart on the validator' do
    before(:all) do
      @connection = Solace::Connection.new(commitment: 'processed')
      bob         = Fixtures.load_keypair('bob')
      @recipient  = Solace::Keypair.generate

      @table = LookupTableProvisioner.provision(connection: @connection, authority: bob, addresses: [@recipient.address])

      transfer = Solace::Composers::SystemProgramTransferComposer.new(from: bob, to: @recipient, lamports: 5_000_000)
      original = Solace::TransactionComposer.new(connection: @connection)
                                            .add_instruction(transfer)
                                            .set_fee_payer(bob)
                                            .set_compute_budget(units: 20_000)
                                            .add_address_lookup_table(account: @table, addresses: [@recipient.address])
                                            .compose_transaction

      @recovered   = Solace::TransactionDecomposer.new(connection: @connection).decompose_transaction(original.serialize)
      @transaction = @recovered.compose_transaction
      @transaction.sign(bob)

      @identical = original.message.serialize == @transaction.message.serialize

      signature = @connection.send_transaction(@transaction.serialize)
      @connection.wait_for_confirmed_signature { signature['result'] }
    end

    it 'reads the table from chain and recomposes the same bytes' do
      assert_equal [@recipient.address], @recovered.address_lookup_tables.first.addresses
      assert @identical
    end

    it 'lands on chain through the loaded address' do
      assert_equal 5_000_000, @connection.get_balance(@recipient.address)
    end
  end
end

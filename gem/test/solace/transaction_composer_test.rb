# frozen_string_literal: true

require 'test_helper'

describe Solace::TransactionComposer do
  let(:connection) { Solace::Connection.new }
  let(:composer) { Solace::TransactionComposer.new(connection: connection) }

  # Mint
  let(:mint_keypair) { Fixtures.load_keypair('mint') }
  let(:mint_authority) { Fixtures.load_keypair('mint_authority') }
  let(:freeze_authority) { Fixtures.load_keypair('freeze_authority') }

  # Test keypairs
  let(:random_keypair) { Solace::Keypair.generate }
  let(:bob_keypair) { Fixtures.load_keypair('bob') }
  let(:anna_keypair) { Fixtures.load_keypair('anna') }
  let(:payer_keypair) { Fixtures.load_keypair('payer') }

  # Test atas
  let(:bob_ata) { Solace::Programs::AssociatedTokenAccount.get_address(owner: bob_keypair, mint: anna_keypair) }
  let(:anna_ata) { Solace::Programs::AssociatedTokenAccount.get_address(owner: anna_keypair, mint: anna_keypair) }

  # Test programs
  let(:system_program) { Solace::Constants::SYSTEM_PROGRAM_ID }
  let(:spl_token_program) { Solace::Constants::TOKEN_PROGRAM_ID }

  # Test composers
  let(:transfer_composer1) do
    Solace::Composers::SystemProgramTransferComposer.new(
      from:     anna_keypair,
      to:       bob_keypair,
      lamports: 1000
    )
  end

  let(:transfer_composer2) do
    Solace::Composers::SystemProgramTransferComposer.new(
      from:     bob_keypair,
      to:       random_keypair,
      lamports: 2000
    )
  end

  describe '#initialize' do
    it 'creates a new composer with connection' do
      assert_equal connection, composer.connection
    end

    it 'has a instruction composers array' do
      assert_equal [], composer.instruction_composers
    end

    it 'has a transaction context (account context)' do
      assert_instance_of Solace::Utils::AccountContext, composer.context
    end
  end

  describe '#add_instruction' do
    it 'adds instruction composer and returns self for chaining' do
      result = composer.add_instruction(transfer_composer1)

      assert_equal composer, result
      assert_equal 1, composer.instruction_composers.length
      assert_equal transfer_composer1, composer.instruction_composers.first
    end

    it 'merges accounts from instruction composer into transaction context' do
      composer.add_instruction(transfer_composer1)

      tx_context = composer.context

      # Verify accounts are present using predicate methods
      assert tx_context.signer?(anna_keypair.address)
      assert tx_context.writable?(anna_keypair.address)
      assert tx_context.writable_signer?(anna_keypair.address)

      assert tx_context.writable?(bob_keypair.address)
      refute tx_context.signer?(bob_keypair.address)
      assert tx_context.writable_nonsigner?(bob_keypair.address)

      assert tx_context.readonly_nonsigner?(system_program)
    end

    it 'handles multiple instruction composers with account deduplication' do
      composer
        .add_instruction(transfer_composer1)
        .add_instruction(transfer_composer2)

      assert_equal 2, composer.instruction_composers.length

      tx_context = composer.context

      # Anna should be a signer (from transfer_composer1)
      assert tx_context.writable_signer?(anna_keypair.address)

      # Bob should be writable (appears in both transfers)
      assert tx_context.writable?(bob_keypair.address)

      # Random should be writable (from transfer_composer2)
      assert tx_context.writable_nonsigner?(random_keypair.address)

      # System program should be readonly
      assert tx_context.readonly_nonsigner?(system_program)
    end
  end

  describe '#prepend_instruction' do
    it 'prepends instruction composer and returns self for chaining' do
      result = composer
               .add_instruction(transfer_composer2)
               .prepend_instruction(transfer_composer1)

      assert_equal composer, result
      assert_equal 2, composer.instruction_composers.length
      assert_equal transfer_composer1, composer.instruction_composers.first
      assert_equal transfer_composer2, composer.instruction_composers.last
    end
  end

  describe '#insert_instruction' do
    let(:transfer_composer_middle) do
      Solace::Composers::SystemProgramTransferComposer.new(
        from:     payer_keypair,
        to:       random_keypair,
        lamports: 500
      )
    end

    it 'inserts instruction composer at index and returns self for chaining' do
      result = composer
               .add_instruction(transfer_composer1)
               .add_instruction(transfer_composer2)
               .insert_instruction(1, transfer_composer_middle)

      assert_equal composer, result

      assert_equal 3, composer.instruction_composers.length
      assert_equal transfer_composer1, composer.instruction_composers.first
      assert_equal transfer_composer_middle, composer.instruction_composers.at(1)
      assert_equal transfer_composer2, composer.instruction_composers.last
    end
  end

  describe '#set_fee_payer' do
    it 'sets fee payer and returns self for chaining' do
      result = composer.set_fee_payer(payer_keypair)

      assert_equal composer, result
      assert composer.context.fee_payer?(payer_keypair.address)
    end
  end

  describe '#merge' do
    let(:other_composer) { Solace::TransactionComposer.new(connection: connection) }

    let(:another_instruction_composer) do
      Solace::Composers::SystemProgramTransferComposer.new(
        from:     bob_keypair,
        to:       anna_keypair,
        lamports: 1500
      )
    end

    before do
      # Set up main composer
      composer
        .add_instruction(transfer_composer1)
        .add_instruction(transfer_composer2)

      # Set up other composer
      other_composer.add_instruction(another_instruction_composer)
    end

    it 'merges another composer into current composer using default :add placement' do
      result = composer.merge(other_composer)

      assert_equal composer, result
      assert_equal composer.instruction_composers.length, 3

      # Verify order: original two followed by the merged one
      assert_equal transfer_composer1, composer.instruction_composers.first
      assert_equal transfer_composer2, composer.instruction_composers[1]
      assert_equal another_instruction_composer, composer.instruction_composers.last
    end

    it 'merges another composer into current composer using :prepend placement' do
      result = composer.merge(other_composer, placement: :prepend)

      assert_equal composer, result
      assert_equal composer.instruction_composers.length, 3

      # Verify order: merged one followed by the original two
      assert_equal another_instruction_composer, composer.instruction_composers.first
      assert_equal transfer_composer1, composer.instruction_composers[1]
      assert_equal transfer_composer2, composer.instruction_composers.last
    end

    it 'merges another composer into current composer using :insert placement at index' do
      result = composer.merge(other_composer, placement: :insert, index: 1)

      assert_equal composer, result
      assert_equal composer.instruction_composers.length, 3

      # Verify order: first original, then merged, then second original
      assert_equal transfer_composer1, composer.instruction_composers.first
      assert_equal another_instruction_composer, composer.instruction_composers[1]
      assert_equal transfer_composer2, composer.instruction_composers.last
    end
  end

  describe '#set_version' do
    before do
      def connection.get_latest_blockhash
        ['EkSnNWid2cvwEVnVx9aBqawnmiCNiDgp3gUdkDPTKN1N', 1000]
      end

      composer.add_instruction(transfer_composer1).set_fee_payer(payer_keypair)
    end

    it 'composes a v0 message without any table' do
      message = composer.set_version(0).compose_transaction.message

      assert_equal 0, composer.version
      assert_equal 0, message.version
      assert_empty message.address_lookup_tables
      assert_equal 0, Solace::Transaction.from(composer.compose_transaction.serialize).message.version
    end

    it 'composes a legacy message when set back to nil' do
      composer.set_version(0).set_version(nil)

      refute_predicate composer.compose_transaction.message, :versioned?
    end

    it 'rejects a version the gem does not know' do
      assert_raises(ArgumentError) { composer.set_version(1) }
    end
  end

  describe '#set_compute_budget' do
    let(:compute_budget_program) { Solace::Constants::COMPUTE_BUDGET_PROGRAM_ID }
    let(:limit_data) { ->(units) { [2] + [units].pack('L<').bytes } }
    let(:price_data) { ->(micro_lamports) { [3] + [micro_lamports].pack('Q<').bytes } }

    # [program id, data] for each instruction of a composed message
    def programs_and_data(message)
      message.instructions.map { |ix| [message.accounts[ix.program_index], ix.data] }
    end

    before do
      def connection.get_latest_blockhash
        ['EkSnNWid2cvwEVnVx9aBqawnmiCNiDgp3gUdkDPTKN1N', 1000]
      end

      composer.add_instruction(transfer_composer1).set_fee_payer(payer_keypair)
    end

    it 'holds no budget until one is set' do
      assert_instance_of Solace::Utils::ComputeBudget, composer.compute_budget
      refute_predicate composer.compute_budget, :set?
    end

    it 'stores the budget and returns self' do
      result = composer.set_compute_budget(units: 200_000, micro_lamports: 50_000)

      assert_equal composer, result
      assert_equal 200_000, composer.compute_budget.units
      assert_equal 50_000, composer.compute_budget.micro_lamports
    end

    it 'writes the budget instructions first, limit then price' do
      message = composer.set_compute_budget(units: 200_000, micro_lamports: 50_000).compose_transaction.message

      assert_equal 3, message.instructions.length
      assert_equal [compute_budget_program, limit_data[200_000]], programs_and_data(message)[0]
      assert_equal [compute_budget_program, price_data[50_000]], programs_and_data(message)[1]
      assert_equal system_program, programs_and_data(message)[2][0]
    end

    it 'writes only the part of the budget that is set' do
      message = composer.set_compute_budget(units: 200_000).compose_transaction.message

      assert_equal [[compute_budget_program, limit_data[200_000]]], programs_and_data(message).first(1)
      assert_equal 2, message.instructions.length
    end

    it 'replaces a budget composer added as a plain instruction' do
      composer.add_instruction(Solace::Composers::ComputeBudgetProgramSetComputeUnitLimitComposer.new(units: 1_000))
      composer.set_compute_budget(units: 200_000)

      message = composer.compose_transaction.message
      budget  = programs_and_data(message).select { |program, _| program == compute_budget_program }

      assert_equal [[compute_budget_program, limit_data[200_000]]], budget
    end

    it 'leaves a plainly added budget composer alone when no budget is set' do
      composer.add_instruction(Solace::Composers::ComputeBudgetProgramSetComputeUnitLimitComposer.new(units: 1_000))

      message = composer.compose_transaction.message

      assert_nil composer.compute_budget.units
      assert_includes programs_and_data(message), [compute_budget_program, limit_data[1_000]]
    end

    it 'resizes a budget that was already set' do
      composer.set_compute_budget(units: 100_000, micro_lamports: 1)
      composer.set_compute_budget(units: 300_000)

      message = composer.compose_transaction.message

      assert_equal 300_000, composer.compute_budget.units
      assert_nil composer.compute_budget.micro_lamports
      assert_equal 2, message.instructions.length
    end

    describe 'merging another composer' do
      let(:other) { Solace::TransactionComposer.new(connection: connection).add_instruction(transfer_composer2) }

      it 'combines complementary budgets' do
        other.set_compute_budget(micro_lamports: 25)
        composer.set_compute_budget(units: 150_000).merge(other)

        assert_equal 150_000, composer.compute_budget.units
        assert_equal 25, composer.compute_budget.micro_lamports
      end

      it 'takes the other budget where both set the same field' do
        other.set_compute_budget(units: 400_000, micro_lamports: 25)
        composer.set_compute_budget(units: 150_000, micro_lamports: 1).merge(other)

        assert_equal 400_000, composer.compute_budget.units
        assert_equal 25, composer.compute_budget.micro_lamports
      end

      it 'keeps its own budget when the other has none' do
        composer.set_compute_budget(units: 150_000, micro_lamports: 1).merge(other)

        assert_equal 150_000, composer.compute_budget.units
        assert_equal 1, composer.compute_budget.micro_lamports
      end

      it 'adopts the other budget when it has none' do
        other.set_compute_budget(units: 400_000, micro_lamports: 25)
        composer.merge(other)

        assert_equal 400_000, composer.compute_budget.units
        assert_equal 25, composer.compute_budget.micro_lamports
      end

      it 'stays unset when neither has a budget' do
        composer.merge(other)

        refute_predicate composer.compute_budget, :set?
        refute_includes programs_and_data(composer.compose_transaction.message).map(&:first), compute_budget_program
      end

      it 'supersedes budget composers the other added directly' do
        other.add_instruction(Solace::Composers::ComputeBudgetProgramSetComputeUnitLimitComposer.new(units: 1_000))
        composer.set_compute_budget(units: 150_000).merge(other)

        budget = programs_and_data(composer.compose_transaction.message).select { |program, _| program == compute_budget_program }

        assert_equal [[compute_budget_program, limit_data[150_000]]], budget
      end

      it 'writes the merged budget first whatever the placement' do
        other.set_compute_budget(units: 400_000, micro_lamports: 25)
        message = composer.merge(other, placement: :prepend).compose_transaction.message

        assert_equal 4, message.instructions.length
        assert_equal [compute_budget_program, limit_data[400_000]], programs_and_data(message)[0]
        assert_equal [compute_budget_program, price_data[25]], programs_and_data(message)[1]
        assert_equal [system_program, system_program], programs_and_data(message).drop(2).map(&:first)
      end
    end
  end

  describe '#compose_transaction' do
    before do
      # Mock connection to return a blockhash
      def connection.get_latest_blockhash
        ['EkSnNWid2cvwEVnVx9aBqawnmiCNiDgp3gUdkDPTKN1N', 1000]
      end
    end

    it 'composes a single instruction transaction' do
      composer.add_instruction(transfer_composer1)
      composer.set_fee_payer(payer_keypair)

      tx = composer.compose_transaction

      assert_instance_of Solace::Transaction, tx
      assert_instance_of Solace::Message, tx.message
      assert_equal 1, tx.message.instructions.length

      # Verify accounts are in correct order (fee payer first, then signers, then others)
      accounts = tx.message.accounts
      assert_equal payer_keypair.address, accounts[0]  # Fee payer first
      assert_equal anna_keypair.address, accounts[1]   # From account (signer)

      # Verify header
      header = tx.message.header
      assert_equal 2, header[0] # 2 writable signers (fee_payer + from)

      # Verify instruction
      instruction = tx.message.instructions.first
      assert_instance_of Solace::Instruction, instruction
    end

    it 'fetches the latest blockhash when none is supplied' do
      composer.add_instruction(transfer_composer1)
      composer.set_fee_payer(payer_keypair)

      tx = composer.compose_transaction

      assert_equal 'EkSnNWid2cvwEVnVx9aBqawnmiCNiDgp3gUdkDPTKN1N', tx.message.recent_blockhash
    end

    it 'composes against a set blockhash without fetching one' do
      connection.singleton_class.remove_method(:get_latest_blockhash)
      connection.define_singleton_method(:get_latest_blockhash) do
        raise 'get_latest_blockhash should not be called'
      end

      blockhash = '4vJ9JU1bJJE96FWSJKvHsmmFADCg4gpZQff4P3bkLKi'

      composer.add_instruction(transfer_composer1)
      composer.set_fee_payer(payer_keypair)

      tx = composer.set_blockhash(blockhash).compose_transaction

      assert_equal blockhash, composer.blockhash
      assert_equal blockhash, tx.message.recent_blockhash

      decoded = Solace::Transaction.from(tx.serialize).message

      assert_equal blockhash, decoded.recent_blockhash
    end

    it 'composes multi-instruction transaction with account deduplication' do
      composer.add_instruction(transfer_composer1)
      composer.add_instruction(transfer_composer2)
      composer.set_fee_payer(anna_keypair) # Same as from in first transfer

      tx = composer.compose_transaction

      assert_instance_of Solace::Transaction, tx
      assert_equal 2, tx.message.instructions.length

      # Anna should appear only once in accounts despite being fee payer and from account
      accounts = tx.message.accounts

      anna_count = accounts.count { |addr| addr == anna_keypair.address }
      assert_equal 1, anna_count, 'Anna should appear only once in accounts'

      # Anna should be first (fee payer)
      assert_equal anna_keypair.address, accounts[0]
    end

    it 'handles empty transaction' do
      composer.set_fee_payer(payer_keypair)

      tx = composer.compose_transaction

      assert_instance_of Solace::Transaction, tx

      assert_equal 1, tx.message.accounts.length # Only fee payer
      assert_equal 0, tx.message.instructions.length
      assert_equal payer_keypair.address, tx.message.accounts[0]
    end
  end

  describe '#add_address_lookup_table' do
    let(:table_account) { Solace::Keypair.generate.address }

    it 'registers the table and returns self for chaining' do
      result = composer.add_address_lookup_table(account: table_account, addresses: [bob_keypair.address])

      assert_equal composer, result
      assert_equal 1, composer.address_lookup_tables.length
      assert_equal table_account, composer.address_lookup_tables.first.account
      assert_equal [bob_keypair.address], composer.address_lookup_tables.first.addresses
    end

    it 'opts the transaction into the v0 format' do
      assert_nil composer.version

      composer.add_address_lookup_table(account: table_account, addresses: [])

      assert_equal 0, composer.version
    end

    it 'ignores a table already registered by account' do
      composer.add_address_lookup_table(account: table_account, addresses: [bob_keypair.address])
      composer.add_address_lookup_table(account: table_account, addresses: [anna_keypair.address])

      assert_equal 1, composer.address_lookup_tables.length
      assert_equal [bob_keypair.address], composer.address_lookup_tables.first.addresses
    end
  end

  describe '#compose_transaction with lookup tables' do
    let(:table_account) { Solace::Keypair.generate.address }
    let(:mint_address) { mint_keypair.address }
    let(:from_token_account) { Solace::Keypair.generate.address }
    let(:to_token_account) { Solace::Keypair.generate.address }
    let(:unrelated_address) { Solace::Keypair.generate.address }

    let(:transfer_checked_composer) do
      Solace::Composers::SplTokenProgramTransferCheckedComposer.new(
        from:      from_token_account,
        to:        to_token_account,
        mint:      mint_address,
        authority: anna_keypair,
        amount:    1_000,
        decimals:  6
      )
    end

    before do
      # Mock connection to return a blockhash
      def connection.get_latest_blockhash
        ['EkSnNWid2cvwEVnVx9aBqawnmiCNiDgp3gUdkDPTKN1N', 1000]
      end

      composer
        .add_instruction(transfer_checked_composer)
        .set_fee_payer(payer_keypair)
    end

    describe 'when the table covers loadable accounts' do
      before do
        composer.add_address_lookup_table(
          account:   table_account,
          addresses: [unrelated_address, to_token_account, mint_address, anna_keypair.address, spl_token_program]
        )

        @transaction = composer.compose_transaction
        @message     = @transaction.message
      end

      it 'emits a v0 message' do
        assert_predicate @message, :versioned?
        assert_equal 0, @message.version
      end

      it 'moves loadable accounts out of the static account list' do
        refute_includes @message.accounts, to_token_account
        refute_includes @message.accounts, mint_address

        # Writable, but not present in the table — stays static
        assert_includes @message.accounts, from_token_account
      end

      it 'keeps signers, the fee payer, and program ids static even when listed in the table' do
        assert_equal payer_keypair.address, @message.accounts[0]
        assert_includes @message.accounts, anna_keypair.address
        assert_includes @message.accounts, spl_token_program
      end

      it 'drops loaded readonly accounts from the readonly unsigned count' do
        # payer + authority sign; of the two readonly unsigned accounts
        # (mint + token program) only the program remains static
        assert_equal [2, 0, 1], @message.header
      end

      it 'references loaded accounts through their table positions' do
        assert_equal 1, @message.address_lookup_tables.length

        table = @message.address_lookup_tables.first

        assert_equal table_account, table.account
        assert_equal [1], table.writable_indexes # to_token_account
        assert_equal [2], table.readonly_indexes # mint
      end

      it 'resolves instruction indices against the combined v0 account space' do
        combined = @message.accounts + [to_token_account, mint_address]

        instruction = @message.instructions.first

        assert_equal spl_token_program, combined[instruction.program_index]
        assert_equal(
          [from_token_account, mint_address, to_token_account, anna_keypair.address],
          instruction.accounts.map { |index| combined[index] }
        )
      end

      it 'composes a v0 message against a set blockhash' do
        blockhash = '4vJ9JU1bJJE96FWSJKvHsmmFADCg4gpZQff4P3bkLKi'

        message = composer.set_blockhash(blockhash).compose_transaction.message

        assert_equal 0, message.version
        assert_equal blockhash, message.recent_blockhash
      end

      it 'round-trips through serialization' do
        decoded = Solace::Transaction.from(@transaction.serialize).message

        assert_equal 0, decoded.version
        assert_equal @message.accounts, decoded.accounts
        assert_equal @message.header, decoded.header

        table = decoded.address_lookup_tables.first

        assert_equal table_account, table.account
        assert_equal [1], table.writable_indexes
        assert_equal [2], table.readonly_indexes
      end
    end

    describe 'when no table address is loadable' do
      before do
        composer.add_address_lookup_table(
          account:   table_account,
          addresses: [unrelated_address, anna_keypair.address, spl_token_program]
        )

        @message = composer.compose_transaction.message
      end

      it 'composes a v0 message with no table references and every account static' do
        assert_equal 0, @message.version
        assert_empty @message.address_lookup_tables
        assert_includes @message.accounts, to_token_account
        assert_includes @message.accounts, mint_address
        assert_equal [2, 0, 2], @message.header
      end
    end

    describe 'when no lookup tables were added' do
      before do
        @message = composer.compose_transaction.message
      end

      it 'composes a legacy message' do
        refute_predicate @message, :versioned?
        assert_empty @message.address_lookup_tables
      end
    end
  end

  describe '#merge with lookup tables' do
    let(:table_a) { Solace::Keypair.generate.address }
    let(:table_b) { Solace::Keypair.generate.address }

    it 'folds the tables from the other composer, deduped by account' do
      other = Solace::TransactionComposer.new(connection: connection)
      other.add_address_lookup_table(account: table_b, addresses: [bob_keypair.address])
      other.add_address_lookup_table(account: table_a, addresses: [anna_keypair.address])

      composer.add_address_lookup_table(account: table_a, addresses: [anna_keypair.address])
      composer.merge(other)

      assert_equal [table_a, table_b], composer.address_lookup_tables.map(&:account)
      assert_equal 0, composer.version
    end
  end

  describe 'composing with a compute budget on the validator' do
    before(:all) do
      @connection = Solace::Connection.new(commitment: 'processed')
      bob         = Fixtures.load_keypair('bob')
      @recipient  = Solace::Keypair.generate

      transfer = Solace::Composers::SystemProgramTransferComposer.new(
        from: bob, to: @recipient, lamports: 5_000_000
      )

      # A limit added as a plain instruction would duplicate the setting and
      # be rejected on chain; the setting supersedes it instead
      plain_limit = Solace::Composers::ComputeBudgetProgramSetComputeUnitLimitComposer.new(units: 1_000)

      @transaction = Solace::TransactionComposer.new(connection: @connection)
                                                .add_instruction(plain_limit)
                                                .add_instruction(transfer)
                                                .set_fee_payer(bob)
                                                .set_compute_budget(units: 20_000, micro_lamports: 1)
                                                .compose_transaction
      @transaction.sign(bob)

      signature = @connection.send_transaction(@transaction.serialize)
      @connection.wait_for_confirmed_signature { signature['result'] }
    end

    it 'carries one limit and one price instruction, first' do
      programs = @transaction.message.instructions.map { |ix| @transaction.message.accounts[ix.program_index] }

      assert_equal ([Solace::Constants::COMPUTE_BUDGET_PROGRAM_ID] * 2) + [Solace::Constants::SYSTEM_PROGRAM_ID], programs
    end

    it 'lands on chain' do
      assert_equal 5_000_000, @connection.get_balance(@recipient.address)
    end
  end

  describe 'composing with a compute budget too small for the transaction' do
    before(:all) do
      @connection = Solace::Connection.new(commitment: 'processed')
      bob         = Fixtures.load_keypair('bob')

      transfer = Solace::Composers::SystemProgramTransferComposer.new(
        from: bob, to: Solace::Keypair.generate, lamports: 5_000_000
      )

      @transaction = Solace::TransactionComposer.new(connection: @connection)
                                                .add_instruction(transfer)
                                                .set_fee_payer(bob)
                                                .set_compute_budget(units: 100)
                                                .compose_transaction
      @transaction.sign(bob)
    end

    it 'is rejected by the node for exceeding the limit' do
      error = assert_raises(Solace::Errors::RPCError) do
        @connection.send_transaction(@transaction.serialize)
      end

      assert_match(/exceeded/i, error.message)
    end
  end

  describe 'composing against a set blockhash on the validator' do
    before(:all) do
      @connection = Solace::Connection.new(commitment: 'processed')
      bob         = Fixtures.load_keypair('bob')
      @recipient  = Solace::Keypair.generate
      @blockhash  = @connection.get_latest_blockhash[0]

      transfer = Solace::Composers::SystemProgramTransferComposer.new(
        from: bob, to: @recipient, lamports: 5_000_000
      )

      @transaction = Solace::TransactionComposer.new(connection: @connection)
                                                .add_instruction(transfer)
                                                .set_fee_payer(bob)
                                                .set_blockhash(@blockhash)
                                                .compose_transaction
      @transaction.sign(bob)

      signature = @connection.send_transaction(@transaction.serialize)
      @connection.wait_for_confirmed_signature { signature['result'] }
    end

    it 'carries the set blockhash' do
      assert_equal @blockhash, @transaction.message.recent_blockhash
    end

    it 'lands on chain' do
      assert_equal 5_000_000, @connection.get_balance(@recipient.address)
    end
  end

  describe 'composing v0 transactions against the validator' do
    # Land a v0 transfer of `lamports` from `from` to each recipient, loading
    # through the given registered tables, and return the composed message.
    def land_transfers(connection:, from:, recipients:, tables:)
      composer = Solace::TransactionComposer.new(connection: connection)

      recipients.each do |recipient, lamports|
        transfer = Solace::Composers::SystemProgramTransferComposer.new(
          from: from, to: recipient, lamports: lamports
        )

        composer.add_instruction(transfer)
      end

      composer.set_fee_payer(from)
      tables.each { |account, addresses| composer.add_address_lookup_table(account: account, addresses: addresses) }

      transaction = composer.compose_transaction
      transaction.sign(from)

      signature = connection.send_transaction(transaction.serialize)
      connection.wait_for_confirmed_signature { signature['result'] }

      transaction.message
    end

    describe 'loading writable recipients through a single table' do
      before(:all) do
        @connection = Solace::Connection.new(commitment: 'processed')
        bob         = Fixtures.load_keypair('bob')
        @recipient1 = Solace::Keypair.generate
        @recipient2 = Solace::Keypair.generate

        @table = LookupTableProvisioner.provision(
          connection: @connection, authority: bob, addresses: [@recipient1.address, @recipient2.address]
        )

        @message = land_transfers(
          connection: @connection,
          from:       bob,
          recipients: {
            @recipient1 => 5_000_000,
            @recipient2 => 6_000_000
          },
          tables:     { @table => [@recipient1.address, @recipient2.address] }
        )
      end

      it 'emits a v0 message with the recipients loaded through the table' do
        assert_equal 0, @message.version

        refute_includes @message.accounts, @recipient1.address
        refute_includes @message.accounts, @recipient2.address

        assert_equal [@table], @message.address_lookup_tables.map(&:account)
        assert_equal [0, 1], @message.address_lookup_tables.first.writable_indexes
        assert_empty @message.address_lookup_tables.first.readonly_indexes
      end

      it 'credits the recipients through the loaded addresses' do
        assert_equal 5_000_000, @connection.get_balance(@recipient1.address)
        assert_equal 6_000_000, @connection.get_balance(@recipient2.address)
      end
    end

    describe 'loading accounts across multiple tables' do
      before(:all) do
        @connection = Solace::Connection.new(commitment: 'processed')
        bob         = Fixtures.load_keypair('bob')
        @recipient1 = Solace::Keypair.generate
        @recipient2 = Solace::Keypair.generate

        @table_a = LookupTableProvisioner.provision(
          connection: @connection, authority: bob, addresses: [@recipient1.address]
        )
        @table_b = LookupTableProvisioner.provision(
          connection: @connection, authority: bob, addresses: [@recipient2.address]
        )

        @message = land_transfers(
          connection: @connection,
          from:       bob,
          recipients: {
            @recipient1 => 5_000_000,
            @recipient2 => 6_000_000
          },
          tables:     {
            @table_a => [@recipient1.address],
            @table_b => [@recipient2.address]
          }
        )
      end

      it 'carries one reference per contributing table' do
        assert_equal [@table_a, @table_b], @message.address_lookup_tables.map(&:account)

        refute_includes @message.accounts, @recipient1.address
        refute_includes @message.accounts, @recipient2.address
      end

      it 'credits recipients loaded from either table' do
        assert_equal 5_000_000, @connection.get_balance(@recipient1.address)
        assert_equal 6_000_000, @connection.get_balance(@recipient2.address)
      end
    end

    describe 'loading some accounts while others stay static' do
      before(:all) do
        @connection = Solace::Connection.new(commitment: 'processed')
        bob         = Fixtures.load_keypair('bob')
        @loaded     = Solace::Keypair.generate
        @static     = Solace::Keypair.generate

        # Only @loaded is stored in the table; @static is not loadable
        @table = LookupTableProvisioner.provision(
          connection: @connection, authority: bob, addresses: [@loaded.address]
        )

        @message = land_transfers(
          connection: @connection,
          from:       bob,
          recipients: {
            @loaded => 5_000_000,
            @static => 6_000_000
          },
          tables:     { @table => [@loaded.address] }
        )
      end

      it 'loads the table account and keeps the untabled account static' do
        refute_includes @message.accounts, @loaded.address
        assert_includes @message.accounts, @static.address
      end

      it 'credits both the loaded and the static recipient' do
        assert_equal 5_000_000, @connection.get_balance(@loaded.address)
        assert_equal 6_000_000, @connection.get_balance(@static.address)
      end
    end

    describe 'when an address is present in more than one table' do
      before(:all) do
        @connection = Solace::Connection.new(commitment: 'processed')
        bob         = Fixtures.load_keypair('bob')
        @recipient  = Solace::Keypair.generate

        @first_table  = LookupTableProvisioner.provision(
          connection: @connection, authority: bob, addresses: [@recipient.address]
        )
        @second_table = LookupTableProvisioner.provision(
          connection: @connection, authority: bob, addresses: [@recipient.address]
        )

        @message = land_transfers(
          connection: @connection,
          from:       bob,
          recipients: { @recipient => 5_000_000 },
          tables:     {
            @first_table => [@recipient.address],
            @second_table => [@recipient.address]
          }
        )
      end

      it 'loads the account from the first table only' do
        assert_equal [@first_table], @message.address_lookup_tables.map(&:account)
        assert_equal [0], @message.address_lookup_tables.first.writable_indexes
      end

      it 'credits the recipient' do
        assert_equal 5_000_000, @connection.get_balance(@recipient.address)
      end
    end

    describe 'loading a readonly account through a table' do
      before(:all) do
        @connection = Solace::Connection.new(commitment: 'processed')
        bob         = Fixtures.load_keypair('bob')
        payer       = Fixtures.load_keypair('payer')
        mint        = Fixtures.load_keypair('mint')

        bob_ata  = Solace::Programs::AssociatedTokenAccount.get_address(owner: bob, mint: mint).first
        anna_ata = Solace::Programs::AssociatedTokenAccount.get_address(owner: Fixtures.load_keypair('anna'), mint: mint).first

        @mint_address = mint.address
        @amount       = 1_000

        # The mint is the readonly account the transfer references — load it through a table
        @table = LookupTableProvisioner.provision(
          connection: @connection, authority: payer, addresses: [@mint_address]
        )

        @anna_starting_balance = @connection.get_token_account_balance(anna_ata)['amount'].to_i

        transfer_composer = Solace::Composers::SplTokenProgramTransferCheckedComposer.new(
          mint: mint, from: bob_ata, to: anna_ata, authority: bob, amount: @amount, decimals: 6
        )

        transaction = Solace::TransactionComposer
                      .new(connection: @connection)
                      .add_instruction(transfer_composer)
                      .set_fee_payer(payer)
                      .add_address_lookup_table(account: @table, addresses: [@mint_address])
                      .compose_transaction

        @message = transaction.message
        transaction.sign(payer, bob)

        signature = @connection.send_transaction(transaction.serialize)
        @connection.wait_for_confirmed_signature { signature['result'] }

        @anna_ending_balance = @connection.get_token_account_balance(anna_ata)['amount'].to_i
      end

      it 'loads the mint as a readonly address' do
        assert_equal 0, @message.version
        refute_includes @message.accounts, @mint_address

        table = @message.address_lookup_tables.first

        assert_equal @table, table.account
        assert_empty table.writable_indexes
        assert_equal [0], table.readonly_indexes
      end

      it 'settles the token transfer through the loaded mint' do
        assert_equal @anna_starting_balance + @amount, @anna_ending_balance
      end
    end
  end
end

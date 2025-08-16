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
  let(:spl_token_program) { Solace::Constants::SPL_TOKEN_PROGRAM_ID }

  # Test composers
  let(:transfer_composer1) do
    Solace::Composers::SystemProgramTransferComposer.new(
      from: anna_keypair,
      to: bob_keypair,
      lamports: 1000
    )
  end

  let(:transfer_composer2) do
    Solace::Composers::SystemProgramTransferComposer.new(
      from: bob_keypair,
      to: random_keypair,
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

  describe '#set_fee_payer' do
    it 'sets fee payer and returns self for chaining' do
      result = composer.set_fee_payer(payer_keypair)

      assert_equal composer, result
      assert composer.context.fee_payer?(payer_keypair.address)
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
end

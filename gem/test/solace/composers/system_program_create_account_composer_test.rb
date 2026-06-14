# frozen_string_literal: true

require 'test_helper'

describe Solace::Composers::SystemProgramCreateAccountComposer do
  let(:payer) { Fixtures.load_keypair('payer') }
  let(:owner) { Fixtures.load_keypair('bob') }

  let(:new_account) { Solace::Keypair.generate }

  let(:connection) { Solace::Connection.new(commitment: 'processed') }
  let(:transaction_composer) { Solace::TransactionComposer.new(connection: connection) }

  let(:lamports) { 897_840 + 5_000 } # rent exemption + buffer for fees for 1 byte account

  describe 'sponsored transaction' do
    let(:composer) do
      Solace::Composers::SystemProgramCreateAccountComposer.new(
        from:        payer,
        new_account: new_account,
        owner:       owner,
        lamports:    lamports,
        space:       1
      )
    end

    before(:all) do
      # Get starting information
      @payer_starting_balance = connection.get_balance(payer.address)
      @account_info_before    = connection.get_account_info(new_account.address)

      # Add instruction and set fee payer
      transaction_composer.add_instruction(composer)
      transaction_composer.set_fee_payer(payer)

      # Compose and sign transaction
      tx = transaction_composer.compose_transaction
      tx.sign(payer, new_account)

      # Send transaction and wait for confirmation
      @signature = connection.send_transaction(tx.serialize)
      connection.wait_for_confirmed_signature { @signature['result'] }

      # Get ending information
      @payer_ending_balance = connection.get_balance(payer.address)
      @account_info_after   = connection.get_account_info(new_account.address)
    end

    it 'it deducts lamports from the payer' do
      # 2 signature + 5000 lamports per signature + lamports to new account
      assert_equal @payer_ending_balance, @payer_starting_balance - (2 * 5000) - lamports
    end

    it 'creates the new account with correct balance and owner' do
      # New account did not exist before
      assert_nil @account_info_before

      # New account exists after
      assert_equal @account_info_after['lamports'], lamports
      assert_equal @account_info_after['owner'], owner.address
    end
  end

  describe 'transaction with multiple instructions' do
    let(:new_account_one) { Solace::Keypair.generate }
    let(:new_account_two) { Solace::Keypair.generate }

    let(:composer1) do
      Solace::Composers::SystemProgramCreateAccountComposer.new(
        from:        payer,
        new_account: new_account_one,
        owner:       Solace::Constants::SYSTEM_PROGRAM_ID,
        lamports:    lamports,
        space:       1
      )
    end

    let(:composer2) do
      Solace::Composers::SystemProgramCreateAccountComposer.new(
        from:        payer,
        new_account: new_account_two,
        owner:       Solace::Constants::SYSTEM_PROGRAM_ID,
        lamports:    lamports,
        space:       1
      )
    end

    before(:all) do
      # Get starting information
      @payer_starting_balance  = connection.get_balance(payer.address)
      @account_info_one_before = connection.get_account_info(new_account_one.address)
      @account_info_two_before = connection.get_account_info(new_account_two.address)

      # Add instructions and set fee payer
      transaction_composer.add_instruction(composer1)
      transaction_composer.add_instruction(composer2)
      transaction_composer.set_fee_payer(payer)

      # Compose and sign transaction
      tx = transaction_composer.compose_transaction
      tx.sign(payer, new_account_one, new_account_two)

      # Send transaction and wait for confirmation
      @signature = connection.send_transaction(tx.serialize)
      connection.wait_for_confirmed_signature { @signature['result'] }

      # Get ending information
      @payer_ending_balance   = connection.get_balance(payer.address)
      @account_info_one_after = connection.get_account_info(new_account_one.address)
      @account_info_two_after = connection.get_account_info(new_account_two.address)
    end

    it 'creates the first new account with correct balance and owner' do
      assert_nil @account_info_one_before

      assert_equal @account_info_one_after['lamports'], lamports
      assert_equal @account_info_one_after['owner'], Solace::Constants::SYSTEM_PROGRAM_ID
    end

    it 'creates the second new account with correct balance and owner' do
      assert_nil @account_info_two_before

      assert_equal @account_info_two_after['lamports'], lamports
      assert_equal @account_info_two_after['owner'], Solace::Constants::SYSTEM_PROGRAM_ID
    end

    it 'deducts lamports from the payer' do
      # 3 signature + 5000 lamports per signature + lamports to each new account
      assert_equal @payer_ending_balance, @payer_starting_balance - (3 * 5000) - (2 * lamports)
    end
  end
end

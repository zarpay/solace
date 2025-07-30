# frozen_string_literal: true

require 'test_helper'

describe Solace::Composers::SplTokenProgramTransferCheckedComposer do
  let(:bob) { Fixtures.load_keypair('bob') }
  let(:anna) { Fixtures.load_keypair('anna') }
  let(:payer) { Fixtures.load_keypair('payer') }
  let(:mint) { Fixtures.load_keypair('mint') }
  let(:fee_collector) { Fixtures.load_keypair('fee-collector') }

  let(:bob_ata) { Solace::Programs::AssociatedTokenAccount.get_address(owner: bob, mint: mint).first }
  let(:anna_ata) { Solace::Programs::AssociatedTokenAccount.get_address(owner: anna, mint: mint).first }
  let(:fee_collector_ata) { Solace::Programs::AssociatedTokenAccount.get_address(owner: fee_collector, mint: mint).first }

  let(:decimals) { 6 }
  let(:amount) { 1_000 }

  let(:connection) { Solace::Connection.new }
  let(:transaction_composer) { Solace::TransactionComposer.new(connection: connection) }

  describe 'sponsored transaction' do
    let(:composer) do
      Solace::Composers::SplTokenProgramTransferCheckedComposer.new(
        mint: mint,
        to: anna_ata,
        from: bob_ata,
        authority: bob,
        amount: amount,
        decimals: decimals
      )
    end

    before(:all) do
      # Get starting balances
      @payer_starting_balance = connection.get_balance(payer.address)
      @bob_starting_token_balance = connection.get_token_account_balance(bob_ata)['amount'].to_i
      @anna_starting_token_balance = connection.get_token_account_balance(anna_ata)['amount'].to_i

      # Set fee payer and add instruction
      transaction_composer.add_instruction(composer)
      transaction_composer.set_fee_payer(payer)

      # Compose and sign transaction
      tx = transaction_composer.compose_transaction
      tx.sign(payer, bob)

      # Send transaction and wait for confirmation
      @signature = connection.send_transaction(tx.serialize)
      connection.wait_for_confirmed_signature { @signature['result'] }

      # Get ending balances
      @payer_ending_balance = connection.get_balance(payer.address)
      @bob_ending_token_balance = connection.get_token_account_balance(bob_ata)['amount'].to_i
      @anna_ending_token_balance = connection.get_token_account_balance(anna_ata)['amount'].to_i
    end

    it 'transfers tokens from bob' do
      assert_equal @bob_ending_token_balance, @bob_starting_token_balance - amount
    end

    it 'transfers tokens to anna' do
      assert_equal @anna_ending_token_balance, @anna_starting_token_balance + amount
    end

    it 'deducts fees from payer' do
      assert_equal @payer_ending_balance, @payer_starting_balance - (2 * 5000)
    end
  end

  describe 'non-sponsored transaction' do
    let(:composer) do
      Solace::Composers::SplTokenProgramTransferCheckedComposer.new(
        mint: mint,
        to: anna_ata,
        from: bob_ata,
        authority: bob,
        amount: amount,
        decimals: decimals
      )
    end

    before(:all) do
      # Get starting balances
      @bob_starting_balance = connection.get_balance(bob.address)
      @bob_starting_token_balance = connection.get_token_account_balance(bob_ata)['amount'].to_i
      @anna_starting_token_balance = connection.get_token_account_balance(anna_ata)['amount'].to_i

      # Add instruction and set fee payer
      transaction_composer.add_instruction(composer)
      transaction_composer.set_fee_payer(bob)

      # Compose and sign transaction
      tx = transaction_composer.compose_transaction
      tx.sign(bob)

      # Send transaction and wait for confirmation
      @signature = connection.send_transaction(tx.serialize)
      connection.wait_for_confirmed_signature { @signature['result'] }

      # Get ending balances
      @bob_ending_balance = connection.get_balance(bob.address)
      @bob_ending_token_balance = connection.get_token_account_balance(bob_ata)['amount'].to_i
      @anna_ending_token_balance = connection.get_token_account_balance(anna_ata)['amount'].to_i
    end

    it 'transfers tokens from bob' do
      assert_equal @bob_ending_token_balance, @bob_starting_token_balance - amount
    end

    it 'transfers tokens to anna' do
      assert_equal @anna_ending_token_balance, @anna_starting_token_balance + amount
    end

    it 'deducts fees from bob' do
      assert_equal @bob_ending_balance, @bob_starting_balance - 5000
    end
  end

  describe 'transaction with multiple instructions' do
    let(:fee) { 10_000 }
    let(:lamports) { 50_000 }

    let(:composer1) do
      Solace::Composers::SplTokenProgramTransferCheckedComposer.new(
        mint: mint,
        to: anna_ata,
        from: bob_ata,
        authority: bob,
        amount: amount,
        decimals: decimals
      )
    end

    let(:composer2) do
      Solace::Composers::SplTokenProgramTransferCheckedComposer.new(
        mint: mint,
        to: fee_collector_ata,
        from: bob_ata,
        authority: bob,
        amount: fee,
        decimals: decimals
      )
    end

    let(:composer3) do
      Solace::Composers::SystemProgramTransferComposer.new(
        to: bob,
        from: anna,
        lamports: lamports
      )
    end

    before(:all) do
      # Get starting balances
      @payer_starting_balance = connection.get_balance(payer.address)
      @bob_starting_balance = connection.get_balance(bob.address)
      @anna_starting_balance = connection.get_balance(anna.address)

      @bob_starting_token_balance = connection.get_token_account_balance(bob_ata)['amount'].to_i
      @anna_starting_token_balance = connection.get_token_account_balance(anna_ata)['amount'].to_i
      @fee_collector_starting_balance = connection.get_token_account_balance(fee_collector_ata)['amount'].to_i

      # Add instructions and set fee payer
      transaction_composer.add_instruction(composer1)
      transaction_composer.add_instruction(composer2)
      transaction_composer.add_instruction(composer3)
      transaction_composer.set_fee_payer(payer)

      # Compose and sign transaction
      tx = transaction_composer.compose_transaction
      tx.sign(payer, bob, anna)

      # Send transaction and wait for confirmation
      @signature = connection.send_transaction(tx.serialize)
      connection.wait_for_confirmed_signature { @signature['result'] }

      # Get ending balances
      @payer_ending_balance = connection.get_balance(payer.address)
      @bob_ending_balance = connection.get_balance(bob.address)
      @anna_ending_balance = connection.get_balance(anna.address)

      @bob_ending_token_balance = connection.get_token_account_balance(bob_ata)['amount'].to_i
      @anna_ending_token_balance = connection.get_token_account_balance(anna_ata)['amount'].to_i
      @fee_collector_ending_balance = connection.get_token_account_balance(fee_collector_ata)['amount'].to_i
    end

    it 'transfers tokens from bob' do
      assert_equal @bob_ending_token_balance, @bob_starting_token_balance - (amount + fee)
    end

    it 'transfers tokens to anna' do
      assert_equal @anna_ending_token_balance, @anna_starting_token_balance + amount
    end

    it 'transfers tokens to fee collector' do
      assert_equal @fee_collector_ending_balance, @fee_collector_starting_balance + fee
    end

    it 'transfers lamports to bob' do
      assert_equal @bob_ending_balance, @bob_starting_balance + lamports
    end

    it 'transfers lamports from anna' do
      assert_equal @anna_ending_balance, @anna_starting_balance - lamports
    end

    it 'deducts fees from payer' do
      assert_equal @payer_ending_balance, @payer_starting_balance - (
        5000 + # transfer from anna
        5000 + # transfer from bob
        5000 # fee payer signature
      )
    end
  end
end

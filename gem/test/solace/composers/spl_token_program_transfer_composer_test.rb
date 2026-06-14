# frozen_string_literal: true

require 'test_helper'

describe Solace::Composers::SplTokenProgramTransferComposer do
  let(:bob) { Fixtures.load_keypair('bob') }
  let(:anna) { Fixtures.load_keypair('anna') }
  let(:payer) { Fixtures.load_keypair('payer') }

  let(:mint) { Fixtures.load_keypair('mint') }

  let(:bob_ata) { Solace::Programs::AssociatedTokenAccount.get_address(owner: bob, mint: mint).first }
  let(:anna_ata) { Solace::Programs::AssociatedTokenAccount.get_address(owner: anna, mint: mint).first }

  let(:amount) { 10 }

  let(:connection) { Solace::Connection.new }
  let(:transaction_composer) { Solace::TransactionComposer.new(connection: connection) }

  let(:composer) do
    Solace::Composers::SplTokenProgramTransferComposer.new(
      owner:       bob,
      source:      bob_ata,
      destination: anna_ata,
      amount:      amount
    )
  end

  describe 'sponsored transaction' do
    before(:all) do
      # Get starting balances
      @payer_starting_balance      = connection.get_balance(payer.address)
      @bob_starting_token_balance  = connection.get_token_account_balance(bob_ata)['amount'].to_i
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
      @payer_ending_balance      = connection.get_balance(payer.address)
      @bob_ending_token_balance  = connection.get_token_account_balance(bob_ata)['amount'].to_i
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
    before(:all) do
      # Get starting balances
      @bob_starting_balance        = connection.get_balance(bob.address)
      @bob_starting_token_balance  = connection.get_token_account_balance(bob_ata)['amount'].to_i
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
      @bob_ending_balance        = connection.get_balance(bob.address)
      @bob_ending_token_balance  = connection.get_token_account_balance(bob_ata)['amount'].to_i
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
end

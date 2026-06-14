# frozen_string_literal: true

require 'test_helper'

describe Solace::Composers::Token2022ProgramTransferComposer do
  let(:bob) { Fixtures.load_keypair('bob') }
  let(:anna) { Fixtures.load_keypair('anna') }
  let(:payer) { Fixtures.load_keypair('payer') }

  let(:mint) { Fixtures.load_keypair('mint-2022') }

  let(:bob_ata) do
    Solace::Programs::AssociatedTokenAccount.get_address(
      owner:            bob,
      mint:             mint,
      token_program_id: Solace::Constants::TOKEN_2022_PROGRAM_ID
    ).first
  end

  let(:anna_ata) do
    Solace::Programs::AssociatedTokenAccount.get_address(
      owner:            anna,
      mint:             mint,
      token_program_id: Solace::Constants::TOKEN_2022_PROGRAM_ID
    ).first
  end

  let(:amount) { 10 }

  let(:connection) { Solace::Connection.new }
  let(:transaction_composer) { Solace::TransactionComposer.new(connection: connection) }

  let(:composer) do
    Solace::Composers::Token2022ProgramTransferComposer.new(
      owner:       bob,
      source:      bob_ata,
      destination: anna_ata,
      amount:      amount
    )
  end

  describe 'sponsored transaction' do
    before(:all) do
      @payer_starting_balance      = connection.get_balance(payer.address)
      @bob_starting_token_balance  = connection.get_token_account_balance(bob_ata)['amount'].to_i
      @anna_starting_token_balance = connection.get_token_account_balance(anna_ata)['amount'].to_i

      transaction_composer.add_instruction(composer)
      transaction_composer.set_fee_payer(payer)

      tx = transaction_composer.compose_transaction
      tx.sign(payer, bob)

      @signature = connection.send_transaction(tx.serialize)
      connection.wait_for_confirmed_signature { @signature['result'] }

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
      @bob_starting_balance        = connection.get_balance(bob.address)
      @bob_starting_token_balance  = connection.get_token_account_balance(bob_ata)['amount'].to_i
      @anna_starting_token_balance = connection.get_token_account_balance(anna_ata)['amount'].to_i

      transaction_composer.add_instruction(composer)
      transaction_composer.set_fee_payer(bob)

      tx = transaction_composer.compose_transaction
      tx.sign(bob)

      @signature = connection.send_transaction(tx.serialize)
      connection.wait_for_confirmed_signature { @signature['result'] }

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

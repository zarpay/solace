# frozen_string_literal: true

require 'test_helper'

describe Solace::Composers::SystemProgramTransferComposer do
  let(:bob) { Fixtures.load_keypair('bob') }
  let(:anna) { Fixtures.load_keypair('anna') }
  let(:payer) { Fixtures.load_keypair('payer') }

  let(:connection) { Solace::Connection.new }
  let(:transaction_composer) { Solace::TransactionComposer.new(connection:) }
  
  describe "sponsored transaction" do
    let(:composer) do
      Solace::Composers::SystemProgramTransferComposer.new(
        to: anna,
        from: bob,
        lamports: 10_000
      )
    end

    before(:all) do
      # Get starting balances
      @bob_starting_balance = connection.get_balance(bob.address)
      @anna_starting_balance = connection.get_balance(anna.address)
      @payer_starting_balance = connection.get_balance(payer.address)

      # Add instruction and set fee payer
      transaction_composer.add_instruction(composer)
      transaction_composer.set_fee_payer(payer)

      # Compose and sign transaction
      tx = transaction_composer.compose_transaction
      tx.sign(payer, bob)

      # Send transaction and wait for confirmation
      @signature = connection.send_transaction(tx.serialize)
      connection.wait_for_confirmed_signature { @signature['result'] }
    
      # Get ending balances
      @bob_ending_balance = connection.get_balance(bob.address)
      @anna_ending_balance = connection.get_balance(anna.address)
      @payer_ending_balance = connection.get_balance(payer.address)
    end

    it 'it deducts lamports from the payer' do
      # 2 signatures + 5000 lamports per signature
      assert_equal @payer_ending_balance, @payer_starting_balance - (2 * 5000)
    end

    it 'sends lamports to the correct address' do
      assert_equal @anna_ending_balance, @anna_starting_balance + 10_000
    end

    it 'sends lamports from the correct address' do
      assert_equal @bob_ending_balance, @bob_starting_balance - 10_000
    end
  end

  describe "non-sponsored transaction" do
    let(:composer) do
      Solace::Composers::SystemProgramTransferComposer.new(
        to: anna,
        from: bob,
        lamports: 10_000
      )
    end

    before(:all) do
      # Get starting balances
      @bob_starting_balance = connection.get_balance(bob.address)
      @anna_starting_balance = connection.get_balance(anna.address)

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
      @anna_ending_balance = connection.get_balance(anna.address)
    end

    it 'sends lamports to the correct address' do
      assert_equal @anna_ending_balance, @anna_starting_balance + 10_000
    end

    it 'sends lamports and fees from the correct address' do
      # 1 signature + 5000 lamports per signature
      assert_equal @bob_ending_balance, @bob_starting_balance - (10_000 + 5000)
    end
  end

  describe "sponsored transaction with multiple instructions" do
    let(:composer_1) do
      Solace::Composers::SystemProgramTransferComposer.new(
        to: bob,
        from: payer,
        lamports: 10_000
      )
    end

    let(:composer_2) do
      Solace::Composers::SystemProgramTransferComposer.new(
        to: anna,
        from: payer,
        lamports: 10_000
      )
    end

    before(:all) do
      # Get starting balances
      @bob_starting_balance = connection.get_balance(bob.address)
      @anna_starting_balance = connection.get_balance(anna.address)
      @payer_starting_balance = connection.get_balance(payer.address)

      # Add instructions and set fee payer
      transaction_composer.add_instruction(composer_1)
      transaction_composer.add_instruction(composer_2)
      transaction_composer.set_fee_payer(payer)

      # Compose and sign transaction
      tx = transaction_composer.compose_transaction
      tx.sign(payer)

      # Send transaction and wait for confirmation
      @signature = connection.send_transaction(tx.serialize)
      connection.wait_for_confirmed_signature { @signature['result'] }
    
      # Get ending balances
      @bob_ending_balance = connection.get_balance(bob.address)
      @anna_ending_balance = connection.get_balance(anna.address)
      @payer_ending_balance = connection.get_balance(payer.address)
    end

    it 'sends lamports to anna' do
      assert_equal @anna_ending_balance, @anna_starting_balance + 10_000
    end

    it 'sends lamports to bob' do
      assert_equal @bob_ending_balance, @bob_starting_balance + 10_000
    end

    it 'sends lamports and fees from payer' do
      # 1 signature + 5000 lamports per signature
      assert_equal @payer_ending_balance, @payer_starting_balance - (
        10_000 + # transfer to anna
        10_000 + # transfer to bob
        5000 # signature
      )
    end
  end
end
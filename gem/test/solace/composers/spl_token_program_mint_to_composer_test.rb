# frozen_string_literal: true

require 'test_helper'

describe Solace::Composers::SystemProgramCreateAccountComposer do
  # A mint is created during application bootstrap.rb
  let(:mint) { Fixtures.load_keypair('mint') }
  let(:payer) { Fixtures.load_keypair('payer') }
  let(:mint_authority) { Fixtures.load_keypair('mint-authority') }

  # Bob will get some tokens minted to his account
  let(:bob) { Fixtures.load_keypair('bob') }

  let(:connection) { Solace::Connection.new(commitment: 'processed') }
  let(:transaction_composer) { Solace::TransactionComposer.new(connection: connection) }

  let(:tokens) { 100 }

  let(:mint_account) { Solace::Keypair.generate }

  let(:ata_address) do
    Solace::Programs::AssociatedTokenAccount.get_address(
      owner: bob.address,
      mint:  mint.address
    ).first
  end

  # Bob already has an associated token account for the mint created during bootstrap.
  let(:composer) do
    Solace::Composers::SplTokenProgramMintToComposer.new(
      amount:         tokens,
      mint:           mint,
      destination:    ata_address,
      mint_authority: mint_authority
    )
  end

  describe 'mints tokens to a token account' do
    before(:each) do
      # Get starting information
      @payer_starting_balance       = connection.get_balance(payer.address)
      @destination_starting_balance = connection.get_token_account_balance(ata_address)

      # Add instruction and set fee payer
      transaction_composer.add_instruction(composer)
      transaction_composer.set_fee_payer(payer)

      # Compose and sign transaction
      tx = transaction_composer.compose_transaction
      tx.sign(payer, mint_authority)

      # Send transaction and wait for confirmation
      @signature = connection.send_transaction(tx.serialize)
      connection.wait_for_confirmed_signature { @signature['result'] }

      # Get ending information
      @payer_ending_balance       = connection.get_balance(payer.address)
      @destination_ending_balance = connection.get_token_account_balance(ata_address)
    end

    it 'deducts lamports from the payer' do
      # 2 signature + 5000 lamports per signature + lamports to new account
      assert_equal @payer_ending_balance, @payer_starting_balance - (2 * 5000)
    end

    it 'mints the correct amount of tokens to the destination account' do
      start_amount = @destination_starting_balance['amount'].to_i
      end_amount   = @destination_ending_balance['amount'].to_i

      assert_equal end_amount, tokens + start_amount
    end
  end

  describe 'mints tokens to a token account without a payer signing' do
    before(:each) do
      # Get starting information
      @mint_authority_starting_balance = connection.get_balance(mint_authority.address)
      @destination_starting_balance    = connection.get_token_account_balance(ata_address)

      # Add instruction and set fee payer
      transaction_composer.add_instruction(composer)
      transaction_composer.set_fee_payer(mint_authority)

      # Compose and sign transaction
      tx = transaction_composer.compose_transaction
      tx.sign(mint_authority)

      # Send transaction and wait for confirmation
      @signature = connection.send_transaction(tx.serialize)
      connection.wait_for_confirmed_signature { @signature['result'] }

      # Get ending information
      @mint_authority_ending_balance = connection.get_balance(mint_authority.address)
      @destination_ending_balance    = connection.get_token_account_balance(ata_address)
    end

    it 'deducts lamports from the mint authority' do
      # 1 signature + 5000 lamports per signature + lamports to new account
      assert_equal @mint_authority_ending_balance, @mint_authority_starting_balance - (1 * 5000)
    end

    it 'mints the correct amount of tokens to the destination account' do
      start_amount = @destination_starting_balance['amount'].to_i
      end_amount   = @destination_ending_balance['amount'].to_i

      assert_equal end_amount, tokens + start_amount
    end
  end
end

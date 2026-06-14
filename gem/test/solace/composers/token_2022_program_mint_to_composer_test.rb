# frozen_string_literal: true

require 'test_helper'

describe Solace::Composers::Token2022ProgramMintToComposer do
  # The Token-2022 mint is created during application bootstrap.rb
  let(:mint) { Fixtures.load_keypair('mint-2022') }
  let(:payer) { Fixtures.load_keypair('payer') }
  let(:mint_authority) { Fixtures.load_keypair('mint-authority') }

  # Bob will get some tokens minted to his account
  let(:bob) { Fixtures.load_keypair('bob') }

  let(:connection) { Solace::Connection.new(commitment: 'processed') }
  let(:transaction_composer) { Solace::TransactionComposer.new(connection: connection) }

  let(:tokens) { 100 }

  let(:ata_address) do
    Solace::Programs::AssociatedTokenAccount.get_address(
      owner: bob.address,
      mint: mint.address,
      token_program_id: Solace::Constants::TOKEN_2022_PROGRAM_ID
    ).first
  end

  # Bob already has a Token-2022 associated token account for the mint created during bootstrap.
  let(:composer) do
    Solace::Composers::Token2022ProgramMintToComposer.new(
      amount: tokens,
      mint: mint,
      destination: ata_address,
      mint_authority: mint_authority
    )
  end

  describe 'mints tokens to a token account' do
    before(:each) do
      @payer_starting_balance       = connection.get_balance(payer.address)
      @destination_starting_balance = connection.get_token_account_balance(ata_address)

      transaction_composer.add_instruction(composer)
      transaction_composer.set_fee_payer(payer)

      tx = transaction_composer.compose_transaction
      tx.sign(payer, mint_authority)

      @signature = connection.send_transaction(tx.serialize)
      connection.wait_for_confirmed_signature { @signature['result'] }

      @payer_ending_balance       = connection.get_balance(payer.address)
      @destination_ending_balance = connection.get_token_account_balance(ata_address)
    end

    it 'deducts lamports from the payer' do
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
      @mint_authority_starting_balance = connection.get_balance(mint_authority.address)
      @destination_starting_balance    = connection.get_token_account_balance(ata_address)

      transaction_composer.add_instruction(composer)
      transaction_composer.set_fee_payer(mint_authority)

      tx = transaction_composer.compose_transaction
      tx.sign(mint_authority)

      @signature = connection.send_transaction(tx.serialize)
      connection.wait_for_confirmed_signature { @signature['result'] }

      @mint_authority_ending_balance = connection.get_balance(mint_authority.address)
      @destination_ending_balance    = connection.get_token_account_balance(ata_address)
    end

    it 'deducts lamports from the mint authority' do
      assert_equal @mint_authority_ending_balance, @mint_authority_starting_balance - (1 * 5000)
    end

    it 'mints the correct amount of tokens to the destination account' do
      start_amount = @destination_starting_balance['amount'].to_i
      end_amount   = @destination_ending_balance['amount'].to_i

      assert_equal end_amount, tokens + start_amount
    end
  end
end

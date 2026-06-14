# frozen_string_literal: true

require 'test_helper'

describe Solace::Composers::Token2022ProgramInitializeMintComposer do
  let(:payer) { Fixtures.load_keypair('payer') }

  let(:mint_authority) { Solace::Keypair.generate }
  let(:freeze_authority) { Solace::Keypair.generate }

  let(:connection) { Solace::Connection.new(commitment: 'processed') }
  let(:transaction_composer) { Solace::TransactionComposer.new(connection: connection) }

  let(:space) { 82 } # size of mint account
  let(:lamports) { 1_461_600 } # rent exemption for 82 bytes

  describe 'initialize mint' do
    let(:mint_account) { Solace::Keypair.generate }

    let(:create_account_composer) do
      Solace::Composers::SystemProgramCreateAccountComposer.new(
        from:        payer,
        new_account: mint_account,
        owner:       Solace::Constants::TOKEN_2022_PROGRAM_ID,
        lamports:    lamports,
        space:       space
      )
    end

    let(:initialize_mint_composer) do
      Solace::Composers::Token2022ProgramInitializeMintComposer.new(
        decimals:         6,
        mint_authority:   mint_authority.address,
        freeze_authority: freeze_authority.address,
        mint_account:     mint_account.address
      )
    end

    before(:each) do
      @payer_starting_balance = connection.get_balance(payer.address)
      @mint_account_before    = connection.get_account_info(mint_account.address)

      transaction_composer.add_instruction(create_account_composer)
      transaction_composer.add_instruction(initialize_mint_composer)
      transaction_composer.set_fee_payer(payer)

      tx = transaction_composer.compose_transaction
      tx.sign(payer, mint_account)

      @signature = connection.send_transaction(tx.serialize)
      connection.wait_for_confirmed_signature { @signature['result'] }

      @payer_ending_balance = connection.get_balance(payer.address)
      @mint_account_after   = connection.get_account_info(mint_account.address)
    end

    it 'it deducts lamports from the payer' do
      # 2 signature + 5000 lamports per signature + lamports to new account + initialize mint fee
      assert_equal @payer_ending_balance, @payer_starting_balance - (2 * 5000) - lamports
    end

    it 'creates the mint account with correct balance and owner' do
      assert_nil @mint_account_before

      assert_equal @mint_account_after['space'], space
      assert_equal @mint_account_after['owner'], Solace::Constants::TOKEN_2022_PROGRAM_ID
    end
  end

  describe 'initialize mint with no freeze authority' do
    let(:mint_account) { Solace::Keypair.generate }

    let(:create_account_composer) do
      Solace::Composers::SystemProgramCreateAccountComposer.new(
        from:        payer,
        new_account: mint_account,
        owner:       Solace::Constants::TOKEN_2022_PROGRAM_ID,
        lamports:    lamports,
        space:       space
      )
    end

    let(:initialize_mint_composer) do
      Solace::Composers::Token2022ProgramInitializeMintComposer.new(
        decimals:       6,
        mint_authority: mint_authority.address,
        mint_account:   mint_account.address
      )
    end

    it 'composes without error' do
      transaction_composer.add_instruction(create_account_composer)
      transaction_composer.add_instruction(initialize_mint_composer)
      transaction_composer.set_fee_payer(payer)

      tx = transaction_composer.compose_transaction
      tx.sign(payer, mint_account)

      assert tx.message.instructions.length == 2
    end
  end
end

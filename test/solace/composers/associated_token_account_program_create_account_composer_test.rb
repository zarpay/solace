# frozen_string_literal: true

require 'test_helper'

describe Solace::Composers::AssociatedTokenAccountProgramCreateAccountComposer do
  let(:mint) { Fixtures.load_keypair('mint') }
  let(:funder) { Fixtures.load_keypair('bob') }
  let(:payer) { Fixtures.load_keypair('payer') }

  let(:connection) { Solace::Connection.new }
  let(:transaction_composer) { Solace::TransactionComposer.new(connection: connection) }

  describe 'sponsored transaction' do
    let(:owner) { Solace::Keypair.generate }
    let(:owner_ata) { Solace::Programs::AssociatedTokenAccount.get_address(owner: owner, mint: mint).first }

    let(:composer) do
      Solace::Composers::AssociatedTokenAccountProgramCreateAccountComposer.new(
        mint: mint,
        owner: owner,
        funder: funder,
        ata_address: owner_ata
      )
    end

    before(:all) do
      # Get starting balances and data
      @account_starting_data = connection.get_account_info(owner_ata)
      @payer_starting_balance = connection.get_balance(payer.address)
      @funder_starting_balance = connection.get_balance(funder.address)

      # Set fee payer and add instruction
      transaction_composer.add_instruction(composer)
      transaction_composer.set_fee_payer(payer)

      # Compose and sign transaction
      tx = transaction_composer.compose_transaction
      tx.sign(payer, funder)

      # Send transaction and wait for confirmation
      @signature = connection.send_transaction(tx.serialize)
      connection.wait_for_confirmed_signature { @signature['result'] }

      # Get ending balances
      @account_ending_data = connection.get_account_info(owner_ata)
      @payer_ending_balance = connection.get_balance(payer.address)
      @funder_ending_balance = connection.get_balance(funder.address)
    end

    it 'creates the account' do
      assert_nil @account_starting_data
      assert_operator @account_ending_data, :!=, nil
    end

    it 'funds account using funder balance' do
      assert_operator @funder_starting_balance, :>, @funder_ending_balance
    end

    it 'deducts fees from payer' do
      assert_equal @payer_ending_balance, @payer_starting_balance - (2 * 5000)
    end
  end

  describe 'owner-funded transaction' do
    let(:owner) { Solace::Keypair.generate }
    let(:owner_starting_balance) { 5_000_000 }
    let(:owner_ata) { Solace::Programs::AssociatedTokenAccount.get_address(owner: owner, mint: mint).first }

    let(:sol_transfer_composer) do
      Solace::Composers::SystemProgramTransferComposer.new(
        to: owner,
        from: payer,
        lamports: owner_starting_balance
      )
    end

    let(:create_account_composer) do
      Solace::Composers::AssociatedTokenAccountProgramCreateAccountComposer.new(
        mint: mint,
        owner: owner,
        funder: owner,
        ata_address: owner_ata
      )
    end

    before(:all) do
      # Get starting balances and data
      @account_starting_data = connection.get_account_info(owner_ata)

      # Set fee payer and add instructions
      #   The payer will first transfer SOL to the owener so that the owner
      #   may fund their own token account's rent exemption.
      transaction_composer.add_instruction(sol_transfer_composer)
      transaction_composer.add_instruction(create_account_composer)
      transaction_composer.set_fee_payer(payer)

      # Compose and sign transaction
      tx = transaction_composer.compose_transaction
      tx.sign(payer, owner)

      # Send transaction and wait for confirmation
      response = connection.send_transaction(tx.serialize)
      connection.wait_for_confirmed_signature { response['result'] }

      # Get ending balances
      @account_ending_balance = connection.get_balance(owner_ata)
      @owner_ending_balance = connection.get_balance(owner.address)
    end

    it 'creates the account with funding' do
      assert_nil @account_starting_data
      assert_operator @account_ending_balance, :>, 0
    end

    it 'deducts funding from owner' do
      assert_equal @owner_ending_balance, owner_starting_balance - @account_ending_balance
    end
  end
end

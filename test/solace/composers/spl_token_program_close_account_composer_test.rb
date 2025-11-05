# frozen_string_literal: true

require 'test_helper'

describe Solace::Composers::SplTokenProgramCloseAccountComposer do
  let(:payer) { Fixtures.load_keypair('payer') }
  # We'll create a temporary token account to close
  let(:tmp_account) { Solace::Keypair.generate }

  let(:mint) { Fixtures.load_keypair('mint') }

  let(:tmp_account_ata) { Solace::Programs::AssociatedTokenAccount.get_address(owner: tmp_account, mint: mint).first }

  let(:amount) { 10 }

  let(:connection) { Solace::Connection.new }
  let(:transaction_composer) { Solace::TransactionComposer.new(connection: connection) }

  let(:setup_account_tx) do
    tx = Solace::TransactionComposer
         .new(connection: connection)
         .add_instruction(
           # Create an ata for the temporary account
           Solace::Composers::AssociatedTokenAccountProgramCreateAccountComposer.new(
             mint: mint,
             funder: payer,
             owner: tmp_account,
             ata_address: tmp_account_ata
           )
         )
         .set_fee_payer(payer)
         .compose_transaction

    tx.sign(payer)
    tx
  end

  describe 'close a token account' do
    let(:composer) do
      Solace::Composers::SplTokenProgramCloseAccountComposer.new(
        destination: payer,
        authority: tmp_account,
        account: tmp_account_ata
      )
    end

    before(:all) do
      # Send transaction and wait for confirmation
      signature = connection.send_transaction(setup_account_tx.serialize)
      connection.wait_for_confirmed_signature { signature['result'] }

      # Get starting balances
      @payer_starting_balance       = connection.get_balance(payer.address)
      @tmp_account_starting_balance = connection.get_balance(tmp_account_ata)

      # Add instruction and set fee payer
      transaction_composer.add_instruction(composer)
      transaction_composer.set_fee_payer(payer)

      # Compose and sign transaction
      tx = transaction_composer.compose_transaction
      tx.sign(payer, tmp_account)

      # Send transaction and wait for confirmation
      @signature = connection.send_transaction(tx.serialize)
      connection.wait_for_confirmed_signature { @signature['result'] }

      # Get ending balances
      @payer_ending_balance    = connection.get_balance(payer.address)
      @tmp_account_ending_data = connection.get_account_info(tmp_account_ata)
    end

    it 'closes the temporary token account' do
      assert @tmp_account_starting_balance.positive? # Ensure the account had some lamports
      assert_nil @tmp_account_ending_data # and that it is now closed
    end

    it 'deducts lamports from the payer for fees and adds lamports from closed account' do
      # 2 signature + 5000 lamports per signature + lamports to closed account
      assert_equal @payer_ending_balance, (@payer_starting_balance + @tmp_account_starting_balance) - (2 * 5000)
    end
  end
end

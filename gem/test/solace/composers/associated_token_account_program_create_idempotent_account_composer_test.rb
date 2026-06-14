# frozen_string_literal: true

require 'test_helper'

describe Solace::Composers::AssociatedTokenAccountProgramCreateIdempotentAccountComposer do
  let(:mint)           { Fixtures.load_keypair('mint') }
  let(:mint_authority) { Fixtures.load_keypair('mint-authority') }

  let(:funder) { Fixtures.load_keypair('bob') }
  let(:payer)  { Fixtures.load_keypair('payer') }

  let(:connection) { Solace::Connection.new }
  let(:transaction_composer) { Solace::TransactionComposer.new(connection: connection) }

  let(:create_class) { Solace::Composers::AssociatedTokenAccountProgramCreateAccountComposer }
  let(:create_idempotent_class) { Solace::Composers::AssociatedTokenAccountProgramCreateIdempotentAccountComposer }

  let(:create_and_transfer_tx) do
    Solace::TransactionComposer
      .new(connection: connection)
      .add_instruction(
        # This will try to create the ATA that already exists
        Solace::Composers::AssociatedTokenAccountProgramCreateIdempotentAccountComposer.new(
          mint:        mint,
          owner:       to,
          funder:      payer,
          ata_address: to_ata
        )
      )
      .add_instruction(
        # This is just to have a follow-up instruction to see if the transaction completes
        Solace::Composers::SplTokenProgramMintToComposer.new(
          amount:         1_000_000,
          mint:           mint,
          destination:    to_ata,
          mint_authority: mint_authority
        )
      )
      .set_fee_payer(payer)
      .compose_transaction
  end

  it 'inherits from CreateAccount composer' do
    assert create_idempotent_class < create_class
  end

  describe 'when the ATA does not already exists' do
    # Setup: 'to' does not have an ATA for the 'mint' fixture
    let(:to)       { Solace::Keypair.generate }
    let(:to_ata)   { Solace::Programs::AssociatedTokenAccount.get_address(owner: to, mint: mint).first }

    before do
      # Starting balances
      @to_ata_starting_info = connection.get_account_info(to_ata)

      # Sign and send transaction
      create_and_transfer_tx.sign(payer, mint_authority)

      response = connection.send_transaction(create_and_transfer_tx.serialize)
      connection.wait_for_confirmed_signature { response['result'] }

      # Ending balances
      @to_ata_ending_balance = connection.get_token_account_balance(to_ata)['amount'].to_i
    end

    # If the ATA creation had failed, the transfer would not have succeeded
    it 'mints the tokens successfully' do
      # Assert that the ATA did not exist before the transaction
      assert_nil @to_ata_starting_info

      # And now has the minted tokens
      assert_equal @to_ata_ending_balance, 1_000_000
    end
  end

  describe 'when the ATA already exists' do
    # Setup: 'bob' already has an ATA for the 'mint' fixture
    let(:to)       { Fixtures.load_keypair('bob') }
    let(:to_ata)   { Solace::Programs::AssociatedTokenAccount.get_address(owner: to, mint: mint).first }

    before do
      # Starting balances
      @to_ata_starting_balance = connection.get_token_account_balance(to_ata)['amount'].to_i

      # Sign and send transaction
      create_and_transfer_tx.sign(payer, mint_authority)

      response = connection.send_transaction(create_and_transfer_tx.serialize)
      connection.wait_for_confirmed_signature { response['result'] }

      # Ending balances
      @to_ata_ending_balance = connection.get_token_account_balance(to_ata)['amount'].to_i
    end

    # If the ATA creation had failed, the transfer would not have succeeded
    it 'mints the tokens successfully' do
      # The transfer should have succeeded
      assert_equal @to_ata_ending_balance, @to_ata_starting_balance + 1_000_000
    end
  end
end

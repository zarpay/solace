# frozen_string_literal: true

require 'test_helper'

describe Solace::Composers::ComputeBudgetProgramSetComputeUnitPriceComposer do
  let(:bob) { Fixtures.load_keypair('bob') }
  let(:anna) { Fixtures.load_keypair('anna') }
  let(:payer) { Fixtures.load_keypair('payer') }

  let(:connection) { Solace::Connection.new(commitment: 'processed') }
  let(:transaction_composer) { Solace::TransactionComposer.new(connection: connection) }

  let(:composer) do
    Solace::Composers::ComputeBudgetProgramSetComputeUnitPriceComposer.new(
      micro_lamports: 1_000_000
    )
  end

  let(:transfer_composer) do
    Solace::Composers::SystemProgramTransferComposer.new(
      to:       anna,
      from:     bob,
      lamports: 10_000
    )
  end

  describe 'composed transaction' do
    let(:decoded_message) do
      transaction_composer.add_instruction(composer)
      transaction_composer.add_instruction(transfer_composer)
      transaction_composer.set_fee_payer(bob)

      Solace::Transaction.from(transaction_composer.compose_transaction.serialize).message
    end

    it 'includes the set compute unit price instruction' do
      instructions = decoded_message.instructions.map { |ix| [decoded_message.accounts[ix.program_index], ix.data] }

      assert_includes instructions, [
        Solace::Constants::COMPUTE_BUDGET_PROGRAM_ID,
        [3] + [1_000_000].pack('Q<').bytes
      ]
    end
  end

  describe 'sponsored transaction' do
    before(:all) do
      # Get starting balance
      @payer_starting_balance = connection.get_balance(payer.address)

      # Add instructions and set fee payer
      transaction_composer.add_instruction(composer)
      transaction_composer.add_instruction(transfer_composer)
      transaction_composer.set_fee_payer(payer)

      # Compose and sign transaction
      tx = transaction_composer.compose_transaction
      tx.sign(payer, bob)

      # Send transaction and wait for confirmation
      @signature = connection.send_transaction(tx.serialize)
      connection.wait_for_confirmed_signature { @signature['result'] }

      # Get ending balance
      @payer_ending_balance = connection.get_balance(payer.address)
    end

    it 'generates a valid transaction' do
      assert(connection.wait_for_confirmed_signature { @signature['result'] })
    end

    it 'deducts the priority fee from the payer' do
      # 2 signatures + 5000 lamports per signature + a priority fee for the runtime's default compute unit limit
      assert_operator @payer_ending_balance, :<, @payer_starting_balance - (2 * 5000)
    end
  end

  describe 'non-sponsored transaction' do
    before(:all) do
      # Get starting balance
      @bob_starting_balance = connection.get_balance(bob.address)

      # Add instructions and set fee payer
      transaction_composer.add_instruction(composer)
      transaction_composer.add_instruction(transfer_composer)
      transaction_composer.set_fee_payer(bob)

      # Compose and sign transaction
      tx = transaction_composer.compose_transaction
      tx.sign(bob)

      # Send transaction and wait for confirmation
      @signature = connection.send_transaction(tx.serialize)
      connection.wait_for_confirmed_signature { @signature['result'] }

      # Get ending balance
      @bob_ending_balance = connection.get_balance(bob.address)
    end

    it 'generates a valid transaction' do
      assert(connection.wait_for_confirmed_signature { @signature['result'] })
    end

    it 'deducts the priority fee from the sender' do
      # 10_000 lamport transfer + 1 signature + 5000 lamports per signature + a priority fee
      assert_operator @bob_ending_balance, :<, @bob_starting_balance - (10_000 + 5000)
    end
  end
end

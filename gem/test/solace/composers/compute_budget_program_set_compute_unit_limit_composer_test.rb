# frozen_string_literal: true

require 'test_helper'

describe Solace::Composers::ComputeBudgetProgramSetComputeUnitLimitComposer do
  let(:bob) { Fixtures.load_keypair('bob') }
  let(:anna) { Fixtures.load_keypair('anna') }
  let(:payer) { Fixtures.load_keypair('payer') }

  let(:connection) { Solace::Connection.new(commitment: 'processed') }
  let(:transaction_composer) { Solace::TransactionComposer.new(connection: connection) }

  let(:composer) do
    Solace::Composers::ComputeBudgetProgramSetComputeUnitLimitComposer.new(
      units: 20_000
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

    it 'includes the set compute unit limit instruction' do
      instructions = decoded_message.instructions.map { |ix| [decoded_message.accounts[ix.program_index], ix.data] }

      assert_includes instructions, [
        Solace::Constants::COMPUTE_BUDGET_PROGRAM_ID,
        [2] + [20_000].pack('L<').bytes
      ]
    end
  end

  describe 'sponsored transaction' do
    let(:transaction) do
      transaction_composer.add_instruction(composer)
      transaction_composer.add_instruction(transfer_composer)
      transaction_composer.set_fee_payer(payer)

      transaction_composer.compose_transaction.tap { |tx| tx.sign(payer, bob) }
    end

    it 'generates a valid transaction' do
      signature = connection.send_transaction(transaction.serialize)

      assert(connection.wait_for_confirmed_signature { signature['result'] })
    end
  end

  describe 'non-sponsored transaction' do
    let(:transaction) do
      transaction_composer.add_instruction(composer)
      transaction_composer.add_instruction(transfer_composer)
      transaction_composer.set_fee_payer(bob)

      transaction_composer.compose_transaction.tap { |tx| tx.sign(bob) }
    end

    it 'generates a valid transaction' do
      signature = connection.send_transaction(transaction.serialize)

      assert(connection.wait_for_confirmed_signature { signature['result'] })
    end
  end

  describe 'transaction exceeding the compute unit limit' do
    # Requests fewer units than the transaction needs
    let(:composer) do
      Solace::Composers::ComputeBudgetProgramSetComputeUnitLimitComposer.new(
        units: 100
      )
    end

    let(:transaction) do
      transaction_composer.add_instruction(composer)
      transaction_composer.add_instruction(transfer_composer)
      transaction_composer.set_fee_payer(bob)

      transaction_composer.compose_transaction.tap { |tx| tx.sign(bob) }
    end

    it 'is rejected by the node' do
      error = assert_raises(Solace::Errors::RPCError) do
        connection.send_transaction(transaction.serialize)
      end

      assert_match(/exceeded/i, error.message)
    end
  end
end

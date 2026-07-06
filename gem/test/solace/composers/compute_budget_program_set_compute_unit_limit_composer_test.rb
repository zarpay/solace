# frozen_string_literal: true

require 'test_helper'

describe Solace::Composers::ComputeBudgetProgramSetComputeUnitLimitComposer do
  let(:bob) { Fixtures.load_keypair('bob') }
  let(:anna) { Fixtures.load_keypair('anna') }

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
    before(:all) do
      # Add instructions and set fee payer
      transaction_composer.add_instruction(composer)
      transaction_composer.add_instruction(transfer_composer)
      transaction_composer.set_fee_payer(bob)

      # Compose and decode the transaction message
      @decoded_message = Solace::Transaction.from(transaction_composer.compose_transaction.serialize).message
    end

    it 'includes the set compute unit limit instruction' do
      instructions = @decoded_message.instructions.map { |ix| [@decoded_message.accounts[ix.program_index], ix.data] }

      assert_includes instructions, [
        Solace::Constants::COMPUTE_BUDGET_PROGRAM_ID,
        [2] + [20_000].pack('L<').bytes
      ]
    end
  end

  describe 'transaction consuming fewer compute units than the limit' do
    before(:all) do
      # Add instructions and set fee payer
      transaction_composer.add_instruction(composer)
      transaction_composer.add_instruction(transfer_composer)
      transaction_composer.set_fee_payer(bob)

      # Compose and sign transaction
      tx = transaction_composer.compose_transaction
      tx.sign(bob)

      # Send transaction
      @signature = connection.send_transaction(tx.serialize)
    end

    it 'is confirmed by the node' do
      assert(connection.wait_for_confirmed_signature { @signature['result'] })
    end
  end

  describe 'transaction exceeding the compute unit limit' do
    # Requests fewer units than the transaction needs
    let(:composer) do
      Solace::Composers::ComputeBudgetProgramSetComputeUnitLimitComposer.new(
        units: 100
      )
    end

    before(:all) do
      # Add instructions and set fee payer
      transaction_composer.add_instruction(composer)
      transaction_composer.add_instruction(transfer_composer)
      transaction_composer.set_fee_payer(bob)

      # Compose and sign transaction
      @transaction = transaction_composer.compose_transaction
      @transaction.sign(bob)
    end

    it 'is rejected by the node' do
      error = assert_raises(Solace::Errors::RPCError) do
        connection.send_transaction(@transaction.serialize)
      end

      assert_match(/exceeded/i, error.message)
    end
  end
end

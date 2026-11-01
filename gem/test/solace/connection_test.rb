# frozen_string_literal: true

require 'test_helper'

describe Solace::Connection do
  let(:connection) { Solace::Connection.new(commitment: 'processed') }

  describe '#get_block_height' do
    it 'returns the current block height' do
      assert_kind_of Integer, connection.get_block_height
    end

    it 'accepts a commitment override' do
      finalized = connection.get_block_height(commitment: 'finalized')
      processed = connection.get_block_height(commitment: 'processed')

      assert_operator finalized, :<=, processed
    end

    it 'stays at or below the last valid block height' do
      _blockhash, last_valid_block_height = connection.get_latest_blockhash

      assert_operator connection.get_block_height, :<=, last_valid_block_height
    end
  end

  describe '#wait_for_confirmed_signature' do
    let(:signature) { 'sig' }

    # The getSignatureStatuses result for one signature the node has seen
    def signature_status(confirmation_status, err: nil)
      {
        'context' => { 'slot' => 1 },
        'value' => [
          {
            'confirmationStatus' => confirmation_status,
            'err' => err
          }
        ]
      }
    end

    def wait_with_status(status, commitment)
      connection.stub(:get_signature_status, status) do
        connection.wait_for_confirmed_signature(commitment, timeout: 0.05, interval: 0.01) { signature }
      end
    end

    it 'returns when the node reports a commitment above the one awaited' do
      assert_equal signature, wait_with_status(signature_status('finalized'), 'confirmed')
    end

    it 'accepts the commitment as a symbol' do
      assert_equal signature, wait_with_status(signature_status('confirmed'), :confirmed)
    end

    it 'rejects an unknown commitment' do
      assert_raises(ArgumentError) { wait_with_status(signature_status('finalized'), 'rooted') }
    end

    it 'returns for processed when the node reports confirmed' do
      assert_equal signature, wait_with_status(signature_status('confirmed'), 'processed')
    end

    it 'keeps waiting for finalized while the node reports confirmed' do
      assert_raises(Solace::Errors::ConfirmationTimeout) do
        wait_with_status(signature_status('confirmed'), 'finalized')
      end
    end

    it 'raises TransactionFailed when the failed transaction reaches the awaited commitment' do
      err   = { 'InstructionError' => [0, { 'Custom' => 1 }] }
      error = assert_raises(Solace::Errors::TransactionFailed) do
        wait_with_status(signature_status('finalized', err: err), 'confirmed')
      end

      assert_equal signature, error.signature
      assert_equal err, error.transaction_error
    end

    it 'keeps waiting while the failed transaction is below the awaited commitment' do
      assert_raises(Solace::Errors::ConfirmationTimeout) do
        wait_with_status(signature_status('processed', err: { 'AccountInUse' => nil }), 'confirmed')
      end
    end
  end
end

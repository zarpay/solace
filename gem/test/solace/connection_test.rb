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
    let(:instruction_error) { { 'InstructionError' => [0, { 'Custom' => 1 }] } }

    # The getSignatureStatuses result for one signature the node has seen
    def signature_status(confirmation_status, err: nil, confirmations: 0)
      {
        'context' => { 'slot' => 1 },
        'value' => [
          {
            'confirmationStatus' => confirmation_status,
            'confirmations' => confirmations,
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

    it 'returns for processed when the node reports confirmed' do
      assert_equal signature, wait_with_status(signature_status('confirmed'), 'processed')
    end

    it 'keeps waiting for finalized while the node reports confirmed' do
      assert_raises(Solace::Errors::ConfirmationTimeout) do
        wait_with_status(signature_status('confirmed'), 'finalized')
      end
    end

    it 'counts a rooted transaction, a null status with null confirmations, as finalized' do
      assert_equal signature, wait_with_status(signature_status(nil, confirmations: nil), 'finalized')
    end

    it 'does not count a status missing confirmationStatus and confirmations as reached' do
      stripped = {
        'context' => { 'slot' => 1 },
        'value' => [{
          'err' => nil,
          'slot' => 1
        }]
      }

      assert_raises(Solace::Errors::ConfirmationTimeout) { wait_with_status(stripped, 'processed') }
    end

    it 'counts a null status with confirmations counted as confirmed' do
      counted = signature_status(nil, confirmations: 3)

      assert_equal signature, wait_with_status(counted, 'confirmed')
      assert_raises(Solace::Errors::ConfirmationTimeout) { wait_with_status(counted, 'finalized') }
    end

    it 'accepts the commitment as a symbol and reports it as a string on timeout' do
      assert_equal signature, wait_with_status(signature_status('confirmed'), :confirmed)

      error = assert_raises(Solace::Errors::ConfirmationTimeout) do
        wait_with_status(signature_status('confirmed'), :finalized)
      end

      assert_equal 'finalized', error.commitment
    end

    it 'rejects an unknown commitment before reading the signature or polling' do
      read = false
      connection.stub(:get_signature_status, ->(*) { flunk 'polled' }) do
        assert_raises(ArgumentError) do
          connection.wait_for_confirmed_signature('rooted') { read = true }
        end
      end

      refute read
    end

    it 'raises TransactionFailed when the failed transaction reaches the awaited commitment' do
      error = assert_raises(Solace::Errors::TransactionFailed) do
        wait_with_status(signature_status('finalized', err: instruction_error), 'confirmed')
      end

      assert_equal signature, error.signature
      assert_equal 'confirmed', error.commitment
      assert_equal 'finalized', error.reported
      assert_equal instruction_error, error.transaction_error
      refute_kind_of Solace::Errors::Error, error
    end

    it 'raises TransactionFailed for a confirmed failure while finalized is awaited' do
      error = assert_raises(Solace::Errors::TransactionFailed) do
        wait_with_status(signature_status('confirmed', err: instruction_error), 'finalized')
      end

      assert_equal 'finalized', error.commitment
      assert_equal 'confirmed', error.reported
    end

    it 'keeps waiting while the failure is only processed' do
      assert_raises(Solace::Errors::ConfirmationTimeout) do
        wait_with_status(signature_status('processed', err: instruction_error), 'processed')
      end
    end
  end
end

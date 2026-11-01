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

    # Waits while the node answers each poll from answers in turn, repeating the
    # last; an exception in answers is raised by that poll. Returns the wait's
    # result and the timeout each poll's request was given.
    def wait_with_answers(answers, commitment, timeout: 0.05)
      pending = answers.dup
      polls   = []
      poll    = lambda do |_signature, timeout:|
        polls << timeout
        answer = pending.size > 1 ? pending.shift : pending.first
        raise answer if answer.is_a?(Exception)

        answer
      end

      result = connection.stub(:get_signature_status, poll) do
        connection.wait_for_confirmed_signature(commitment, timeout: timeout, interval: 0.01) { signature }
      end
      [result, polls]
    end

    def wait_with_status(status, commitment)
      wait_with_answers([status], commitment).first
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

    it 'counts a status with neither confirmationStatus nor confirmations as finalized' do
      rooted = {
        'context' => { 'slot' => 1 },
        'value' => [{
          'err' => nil,
          'slot' => 1
        }]
      }

      assert_equal signature, wait_with_status(rooted, 'finalized')
    end

    it 'keeps waiting on a null status that still counts confirmations' do
      assert_raises(Solace::Errors::ConfirmationTimeout) do
        wait_with_status(signature_status(nil, confirmations: 3), 'processed')
      end
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

    it 'bounds each poll by the time left before the deadline' do
      processed      = signature_status('processed')
      _result, polls = wait_with_answers([processed, processed, signature_status('confirmed')], 'confirmed', timeout: 1)

      assert_equal 3, polls.size
      assert polls.all?(&:positive?), polls.inspect
      assert_operator polls.first, :<=, 1 + 1e-6
      assert polls.each_cons(2).all? { |earlier, later| later < earlier }, polls.inspect
    end

    {
      'HTTP 408 (request timeout)' => Solace::Errors::HTTPError.new('HTTP timeout', code: 408),
      'HTTP 429' => Solace::Errors::HTTPError.new('Too Many Requests', code: 429),
      'HTTP 503' => Solace::Errors::HTTPError.new('Service Unavailable', code: 503),
      'RPC -32005 (node unhealthy)' => Solace::Errors::RPCError.new('behind', rpc_code: -32_005, rpc_message: 'behind'),
      'RPC -32016 (min context slot)' => Solace::Errors::RPCError.new('slot', rpc_code: -32_016, rpc_message: 'slot'),
      'HTML maintenance page' => Solace::Errors::ParseError.new('Invalid JSON', body: "\n<html>down</html>"),
      'connection reset' => Errno::ECONNRESET.new,
      'connection refused' => Errno::ECONNREFUSED.new,
      'SSL error' => OpenSSL::SSL::SSLError.new('handshake')
    }.each do |name, transient|
      it "keeps polling past a transient #{name}" do
        result, polls = wait_with_answers([transient, signature_status('confirmed')], 'confirmed', timeout: 1)

        assert_equal signature, result
        assert_equal 2, polls.size
      end
    end

    {
      'HTTP 401' => Solace::Errors::HTTPError.new('Unauthorized', code: 401),
      'HTTP 404' => Solace::Errors::HTTPError.new('Not Found', code: 404),
      'RPC -32602 (invalid params)' => Solace::Errors::RPCError.new('bad', rpc_code: -32_602, rpc_message: 'bad'),
      'non-HTML parse error' => Solace::Errors::ParseError.new('Invalid JSON', body: '{"jsonrpc":'),
      'DNS failure' => Solace::Errors::HTTPError.new('HTTP transport error', code: 0)
    }.each do |name, permanent|
      it "raises a permanent #{name} on the first poll" do
        polls = []
        poll  = lambda do |_signature, timeout:|
          polls << timeout
          raise permanent
        end

        raised = connection.stub(:get_signature_status, poll) do
          assert_raises(permanent.class) do
            connection.wait_for_confirmed_signature(timeout: 0.05, interval: 0.01) { signature }
          end
        end

        assert_same permanent, raised
        assert_equal 1, polls.size
      end
    end

    it 'times out naming the last transient error as its cause when every poll errors' do
      unavailable = Solace::Errors::HTTPError.new('Service Unavailable', code: 503)

      error = assert_raises(Solace::Errors::ConfirmationTimeout) { wait_with_status(unavailable, 'confirmed') }

      assert_same unavailable, error.cause
      assert_includes error.message, 'Service Unavailable'
    end

    it 'raises TransactionFailed when the failed transaction reaches the awaited commitment' do
      error = assert_raises(Solace::Errors::TransactionFailed) do
        wait_with_status(signature_status('finalized', err: instruction_error), 'confirmed')
      end

      assert_equal signature, error.signature
      assert_equal 'confirmed', error.commitment
      assert_equal 'finalized', error.reported
      assert_equal instruction_error, error.transaction_error
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

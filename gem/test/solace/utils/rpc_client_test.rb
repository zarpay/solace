# frozen_string_literal: true

require 'test_helper'

describe Solace::Utils::RPCClient do
  let(:url) { 'http://localhost:8899' }
  let(:open_timeout) { 10 }
  let(:read_timeout) { 10 }

  let(:client) { Solace::Utils::RPCClient.new(url, open_timeout: open_timeout, read_timeout: read_timeout) }

  describe '#initialize' do
    it 'assigns url' do
      assert_equal url, client.url
    end

    it 'assigns open_timeout' do
      assert_equal open_timeout, client.open_timeout
    end

    it 'assigns read_timeout' do
      assert_equal read_timeout, client.read_timeout
    end
  end

  describe '#rpc_request' do
    let(:method_name) { 'getMinimumBalanceForRentExemption' }
    let(:params) { [100] }

    it 'calls the RPC endpoint with the correct method and params' do
      response = client.rpc_request(method_name, params)

      assert_kind_of String, response['id']
      assert_kind_of Integer, response['result']
      assert_equal '2.0', response['jsonrpc']
    end

    it 'raises HTTPError timeout when the request times out' do
      Net::HTTP.stub(:start, ->(*) { raise Net::OpenTimeout }) do
        error = assert_raises(Solace::Errors::HTTPError) do
          client.rpc_request(method_name, params)
        end

        assert_equal 408, error.code
      end
    end

    it 'raises HTTPError timeout when there is a read timeout' do
      Net::HTTP.stub(:start, ->(*) { raise Net::ReadTimeout }) do
        error = assert_raises(Solace::Errors::HTTPError) do
          client.rpc_request(method_name, params)
        end

        assert_equal 408, error.code
      end
    end

    it 'raises HTTPError transport when there is a socket error' do
      Net::HTTP.stub(:start, ->(*) { raise SocketError }) do
        error = assert_raises(Solace::Errors::HTTPError) do
          client.rpc_request(method_name, params)
        end

        assert_equal 0, error.code
      end
    end

    it 'raises HTTPError transport when there is an IO error' do
      Net::HTTP.stub(:start, ->(*) { raise IOError }) do
        error = assert_raises(Solace::Errors::HTTPError) do
          client.rpc_request(method_name, params)
        end

        assert_equal 0, error.code
      end
    end

    it 'raises HTTPError when the response is not a success' do
      # Create a Net::HTTPBadRequest instance
      bad_request_response = Net::HTTPBadRequest.new('1.1', 400, 'Bad Request')
      bad_request_response.instance_variable_set(:@read, true) # mark as already read
      bad_request_response.body = 'Mocked body here'

      Net::HTTP.stub(:start, ->(*) { bad_request_response }) do
        error = assert_raises(Solace::Errors::HTTPError) do
          client.rpc_request(method_name, params)
        end

        assert_equal 'HTTP error: Bad Request', error.message
        assert_equal 'Mocked body here', error.body
        assert_equal 400, error.code
      end
    end

    it 'raises ParseError when the response is not a valid JSON' do
      # Create a Net::HTTPSuccess instance
      text_response = Net::HTTPSuccess.new('1.1', 200, 'OK')
      text_response.instance_variable_set(:@read, true)
      text_response.body = 'this is not a valid JSON'

      Net::HTTP.stub(:start, ->(*) { text_response }) do
        error = assert_raises(Solace::Errors::ParseError) do
          client.rpc_request(method_name, params)
        end

        assert_equal 'this is not a valid JSON', error.body
        assert_match(/Invalid JSON from RPC:/, error.message)
      end
    end

    it 'raises RPCError when the response is a JSON-RPC error' do
      # Create a Net::HTTPSuccess instance
      json_rpc_error_response = Net::HTTPSuccess.new('1.1', 200, 'OK')
      json_rpc_error_response.instance_variable_set(:@read, true)
      json_rpc_error_response.body = JSON.dump({ jsonrpc: '2.0', id: '1', error: { code: -32_601, message: 'Method not found', data: 'data' } })

      Net::HTTP.stub(:start, ->(*) { json_rpc_error_response }) do
        error = assert_raises(Solace::Errors::RPCError) do
          client.rpc_request(method_name, params)
        end

        assert_equal 'RPC error -32601: Method not found', error.message
        assert_equal(-32_601, error.rpc_code)
        assert_equal 'data', error.rpc_data
      end
    end
  end
end

# frozen_string_literal: true

require 'offline_helper'

describe Solace::Utils::RPCClient do
  # Stands in for what Rack::Timeout and Sidekiq's shutdown raise into a thread:
  # an Exception that is not a StandardError, arriving mid-call.
  killed = Class.new(Exception) # rubocop:disable Lint/InheritException

  after do
    Solace::Utils::HTTPConnections.clear
    @server&.stop
  end

  def server = @server ||= FakeRPCServer.new

  let(:reuse) { true }

  def client_for(url = server.url, open_timeout: 1, read_timeout: 2, reuse_connections: reuse)
    Solace::Utils::RPCClient.new(
      url,
      open_timeout:      open_timeout,
      read_timeout:      read_timeout,
      reuse_connections: reuse_connections
    )
  end

  def echo(client, *params)
    client.rpc_request('echo', params)['result']
  end

  describe '#initialize' do
    let(:client) { client_for('http://127.0.0.1:1', open_timeout: 1, read_timeout: 2) }

    it 'assigns url' do
      assert_equal 'http://127.0.0.1:1', client.url
    end

    it 'assigns open_timeout' do
      assert_equal 1, client.open_timeout
    end

    it 'assigns read_timeout' do
      assert_equal 2, client.read_timeout
    end
  end

  describe 'connection reuse' do
    it 'serves consecutive calls over one connection' do
      client = client_for
      5.times { |i| echo(client, i) }

      assert_equal 1, server.accepted
    end

    it 'serves calls from separately built clients over one connection' do
      5.times { |i| echo(client_for, i) }

      assert_equal 1, server.accepted
    end

    it 'gives every concurrent caller its own answer' do
      callers = Array.new(8) do |thread|
        Thread.new { Array.new(25) { |call| [[thread, call], echo(client_for, thread, call)['params']] } }
      end
      answers = callers.flat_map { |t| (t.join(20) || flunk('a caller hung')).value }

      answers.each { |asked, answered| assert_equal asked, answered }
      assert_empty server.errors
    end

    it 'never hands a forked child the socket its parent opened' do
      skip 'fork is unavailable on this platform' unless Process.respond_to?(:fork)

      parent_connection = echo(client_for, 'parent')['connection']
      reader, writer    = IO.pipe
      pid               = fork do
        reader.close
        writer.write(JSON.dump(echo(client_for, 'child')))
        exit!(0)
      end
      writer.close
      child_answer      = JSON.parse(reader.read)
      Process.wait(pid)

      assert_equal ['child'], child_answer['params']
      refute_equal parent_connection, child_answer['connection']
      assert_equal ['parent again'], echo(client_for, 'parent again')['params']
    end

    it 'never hands the rest of a killed call\'s answer to the next call on that thread' do
      server.answer_with(:half)
      first_call = lambda do
        echo(client_for, 'first')
      rescue killed
        nil
      end

      caller = Thread.new do
        first_call.call
        server.release!
        echo(client_for, 'second')
      end
      server.wait_for_half_answer
      caller.raise(killed)

      assert_equal ['second'], caller.join(10).value['params']
    end

    it 'replaces a connection the server closed while it sat idle' do
      client = client_for
      echo(client, 'before')
      server.hang_up_idle!

      assert_equal ['after'], echo(client, 'after')['params']
    end

    [:requestAirdrop, 'sendTransaction'].each do |method|
      it "never sends a #{method} twice, even when the reused connection was closed under it" do
        client = client_for
        echo(client, 'opens the connection')
        server.answer_with(:hang_up)

        error = assert_raises(Solace::Errors::HTTPError) { client.rpc_request(method, ['payload']) }

        assert_kind_of EOFError, error.cause
        assert_equal 1, server.accepted
      end
    end

    it 'sends a call once more on a new connection when the server closed the reused one under it' do
      client = client_for
      echo(client, 'opens the connection')
      server.answer_with(:hang_up)

      assert_equal ['resent'], echo(client, 'resent')['params']
      assert_equal 2, server.accepted
    end

    it 'reports a new connection closed under an unanswered call as a transport error caused by EOFError' do
      client = client_for
      echo(client, 'opens the connection')
      server.answer_with(:hang_up)
      server.answer_with(:hang_up)

      error = assert_raises(Solace::Errors::HTTPError) { echo(client, 'lost twice') }

      assert_equal 0, error.code
      assert_kind_of EOFError, error.cause
      assert_equal 2, server.accepted
    end

    it 'closes connections left idle past the keep-alive instead of reusing them' do
      server.answer_with(:half)
      held  = Thread.new { echo(client_for, 'held') }
      server.wait_for_half_answer
      echo(client_for, 'beside it')
      server.release!
      held.join(5)
      later = Process.clock_gettime(Process::CLOCK_MONOTONIC) + Solace::Utils::HTTPConnections::KEEP_ALIVE + 1

      Solace::Utils::HTTPConnections.stub(:now, later) { echo(client_for, 'after the keep-alive') }

      assert_equal 3, server.accepted
      assert_equal 2, server.wait_until_ended(2)
    end

    it 'refuses an answer addressed to a different request' do
      server.answer_with({
                           jsonrpc: '2.0',
                           id:      'someone-else',
                           result:  1
                         })

      error = assert_raises(Solace::Errors::HTTPError) { echo(client_for, 'mine') }

      assert_match(/id/, error.message)
    end
  end

  describe 'without reuse_connections' do
    let(:reuse) { false }

    it 'opens a new connection for every call' do
      client = client_for
      3.times { |i| echo(client, i) }

      assert_equal 3, server.accepted
    end

    it 'returns an answer whatever request id it carries' do
      server.answer_with({
                           jsonrpc: '2.0',
                           id:      'someone-else',
                           result:  1
                         })

      assert_equal 1, client_for.rpc_request('echo', ['mine'])['result']
    end

    it 'is what an RPCClient gets unless it asks for reuse' do
      client = Solace::Utils::RPCClient.new(server.url, open_timeout: 1, read_timeout: 2)
      2.times { |i| echo(client, i) }

      assert_equal 2, server.accepted
    end

    it 'is what a Solace::Connection gets unless it asks for reuse' do
      2.times { Solace::Connection.new(server.url).get_slot }

      assert_equal 2, server.accepted
    end
  end

  describe 'with http_reuse_connections on a Solace::Connection' do
    it 'reuses one connection across calls' do
      2.times { Solace::Connection.new(server.url, http_reuse_connections: true).get_slot }

      assert_equal 1, server.accepted
    end
  end

  [true, false].each do |mode|
    describe "reuse_connections: #{mode}" do
      let(:reuse) { mode }

      describe 'timeouts' do
        it 'holds a caller to its own read timeout on a connection opened with a longer one' do
          echo(client_for(read_timeout: 5), 'opens the connection')
          server.answer_with(:stall)
          started = Process.clock_gettime(Process::CLOCK_MONOTONIC)

          error = assert_raises(Solace::Errors::HTTPError) { echo(client_for(read_timeout: 0.15), 'impatient') }

          assert_equal 408, error.code
          assert_operator Process.clock_gettime(Process::CLOCK_MONOTONIC) - started, :<, 1
        end

        it 'gives a caller its own read timeout on a connection opened with a shorter one' do
          echo(client_for(read_timeout: 0.15), 'opens the connection')
          server.answer_with(:slow)

          assert_equal ['patient'], echo(client_for(read_timeout: 5), 'patient')['params']
        end

        it 'reports an answer slower than the read timeout as a 408 caused by Net::ReadTimeout' do
          server.answer_with(:stall)

          error = assert_raises(Solace::Errors::HTTPError) { echo(client_for(read_timeout: 0.15), 'slow') }

          assert_equal 408, error.code
          assert_kind_of Net::ReadTimeout, error.cause
        end

        it 'reports a handshake slower than the open timeout as a 408 caused by Net::OpenTimeout' do
          # The kernel completes the TCP handshake from the backlog; nobody ever answers the TLS one.
          listener = TCPServer.new('127.0.0.1', 0)
          silent   = client_for("https://127.0.0.1:#{listener.addr[1]}", open_timeout: 0.15)

          error = assert_raises(Solace::Errors::HTTPError) { echo(silent, 'never connects') }
          listener.close

          assert_equal 408, error.code
          assert_kind_of Net::OpenTimeout, error.cause
        end
      end

      describe 'errors' do
        it 'reports a host that does not resolve as a transport error caused by SocketError' do
          error = assert_raises(Solace::Errors::HTTPError) { echo(client_for('http://solace-test.invalid'), 'nowhere') }

          assert_equal 0, error.code
          assert_kind_of SocketError, error.cause
        end

        # Callers that retry a refused connect look for it on the error or its cause.
        it 'surfaces a refused connection as Errno::ECONNREFUSED, raised or as the cause' do
          closed_port = TCPServer.open('127.0.0.1', 0).then { |s| s.addr[1].tap { s.close } }

          error = assert_raises(StandardError) { echo(client_for("http://127.0.0.1:#{closed_port}"), 'refused') }

          assert [error, error.cause].any?(Errno::ECONNREFUSED), "got #{error.class}, caused by #{error.cause.class}"
        end

        it 'raises HTTPError carrying the status and body when the response is not a success' do
          server.answer_with([400, 'Mocked body here'])

          error = assert_raises(Solace::Errors::HTTPError) { echo(client_for, 'bad') }

          assert_equal 'HTTP error: Error', error.message
          assert_equal 'Mocked body here', error.body
          assert_equal 400, error.code
        end

        it 'raises ParseError when the response is not valid JSON' do
          server.answer_with([200, 'this is not a valid JSON'])

          error = assert_raises(Solace::Errors::ParseError) { echo(client_for, 'garbled') }

          assert_equal 'this is not a valid JSON', error.body
          assert_match(/Invalid JSON from RPC:/, error.message)
        end

        it 'raises RPCError for a JSON-RPC error, even one the node could not tie to a request' do
          server.answer_with({
                               jsonrpc: '2.0',
                               id:      nil,
                               error:   {
                                 code:    -32_601,
                                 message: 'Method not found',
                                 data:    'data'
                               }
                             })

          error = assert_raises(Solace::Errors::RPCError) { echo(client_for, 'unknown') }

          assert_equal 'RPC error -32601: Method not found', error.message
          assert_equal(-32_601, error.rpc_code)
          assert_equal 'data', error.rpc_data
        end
      end
    end
  end
end

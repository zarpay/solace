# frozen_string_literal: true

require 'json'
require 'socket'
require 'timeout'

# A JSON-RPC server on a real socket, for tests that turn on what happens to the
# connection rather than on what the node answers.
#
# Every answer echoes the call's params and names the connection that served it,
# so a test can tell from the client side alone which socket carried a call and
# whether the answer it got was its own. `answer_with` scripts the next call's
# answer, for the misbehaviour a test needs.
class FakeRPCServer
  attr_reader :url

  def initialize
    @server    = TCPServer.new('127.0.0.1', 0)
    @url       = "http://127.0.0.1:#{@server.addr[1]}"
    @lock      = Mutex.new
    @accepted  = 0
    @ended     = 0
    @sockets   = []
    @threads   = []
    @scripted  = []
    @errors    = []
    @half_sent = Queue.new
    @released  = Queue.new
    @threads << Thread.new { accept_loop }
  end

  # How many TCP connections clients have opened to this server.
  def accepted = @lock.synchronize { @accepted }

  # How many of those connections have since closed, from either side.
  def ended = @lock.synchronize { @ended }

  # Blocks until `count` connections have ended, or the timeout passes.
  def wait_until_ended(count, timeout: 2)
    deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + timeout
    sleep 0.01 until ended >= count || Process.clock_gettime(Process::CLOCK_MONOTONIC) > deadline
    ended
  end

  # Requests the server could not read as HTTP, such as two writers interleaved
  # on one socket.
  def errors = @lock.synchronize { @errors.dup }

  # Scripts the answer to the next call that has not yet been answered:
  #   :stall      reads the request, then never answers
  #   :slow       answers normally after 0.3s
  #   :half       writes the headers and half the body, then waits for `release!`
  #               before writing the rest and serving the socket again
  #   :hang_up    reads the request, then closes the socket without answering
  #   [status, body] answers with that status and raw body
  #   Hash        answers 200 with that JSON object
  def answer_with(behaviour) = @lock.synchronize { @scripted << behaviour }

  # Blocks until a :half answer has sent its first half.
  def wait_for_half_answer(timeout: 5) = Timeout.timeout(timeout) { @half_sent.pop }

  # Lets a :half answer finish.
  def release! = @released << true

  # Closes every connection from the server's side, as a CDN does to an idle
  # one, and gives the client's kernel a moment to see the FIN.
  def hang_up_idle!
    close_sockets
    sleep 0.05
  end

  def stop
    @server.close
    @lock.synchronize { @threads.dup }.each(&:kill)
    close_sockets
  end

  private

  def close_sockets
    @lock.synchronize { @sockets.dup }.each { |s| s.close unless s.closed? }
  end

  def accept_loop
    loop do
      socket = @server.accept
      id     = @lock.synchronize do
        @sockets << socket
        @accepted += 1
      end
      thread = Thread.new { serve(socket, id) }
      @lock.synchronize { @threads << thread }
    end
  rescue IOError, Errno::EBADF
    nil
  end

  def serve(socket, connection_id)
    loop do
      request   = read_request(socket) or break
      behaviour = @lock.synchronize { @scripted.shift }
      break unless answer?(socket, JSON.dump(echo(connection_id, request)), behaviour)
    end
  rescue IOError, SystemCallError
    nil
  ensure
    socket.close unless socket.closed?
    @lock.synchronize { @ended += 1 }
  end

  # @return [Boolean] whether the socket can serve another request
  def answer?(socket, echo, behaviour)
    case behaviour
    when :hang_up then return false
    when :stall then sleep
    when :half then answer_in_halves(socket, echo)
    when :slow
      sleep 0.3
      respond(socket, 200, echo)
    when Array then respond(socket, *behaviour)
    when Hash then respond(socket, 200, JSON.dump(behaviour))
    else
      respond(socket, 200, echo)
    end
    true
  end

  def respond(socket, status, body)
    socket.write(headers(status, body.bytesize) + body)
  end

  def answer_in_halves(socket, body)
    socket.write(headers(200, body.bytesize) + body[0, body.size / 2])
    @half_sent << true
    @released.pop
    socket.write(body[(body.size / 2)..])
  end

  def echo(connection_id, request)
    {
      jsonrpc: '2.0',
      id:      request['id'],
      result:  {
        'connection' => connection_id,
        'params' => request['params']
      }
    }
  end

  def headers(status, length)
    "HTTP/1.1 #{status} #{status == 200 ? 'OK' : 'Error'}\r\n" \
      "Content-Type: application/json\r\n" \
      "Content-Length: #{length}\r\n" \
      "Connection: keep-alive\r\n\r\n"
  end

  # @return [Hash, nil] the JSON-RPC body, or nil once the client hangs up
  def read_request(socket)
    request_line = socket.gets or return
    return record_error("unexpected request line: #{request_line.inspect}") unless request_line.start_with?('POST ')

    length      = 0
    while (line = socket.gets) && line != "\r\n"
      length = line.split(':', 2).last.to_i if line.downcase.start_with?('content-length:')
    end

    JSON.parse(socket.read(length))
  rescue JSON::ParserError => e
    record_error("unreadable body: #{e.message}")
  end

  def record_error(message)
    @lock.synchronize { @errors << message }
    nil
  end
end

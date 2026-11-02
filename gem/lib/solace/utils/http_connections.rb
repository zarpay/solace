# frozen_string_literal: true

require 'net/http'

module Solace
  module Utils
    # Open HTTP connections shared by every RPCClient in the process, so a call
    # skips the TCP and TLS handshakes when an earlier call left a connection
    # to the same host idle.
    #
    # A connection belongs to one caller at a time: it is checked out for the
    # length of a request and goes back only once that request read its whole
    # answer. Anything that interrupts a request, including an exception that is
    # not a StandardError raised into the thread (a request timeout, a worker
    # shutdown), closes the connection instead, so a half-read answer can never
    # reach the next caller. A forked child starts with no connections, never
    # the sockets its parent opened.
    #
    # @since 0.1.10
    module HTTPConnections
      # Idle connections kept per host; a burst of callers beyond this opens
      # its own connections and closes the extras when they finish.
      MAX_IDLE = 16

      # How long an idle connection is trusted before it is replaced rather than
      # reused. Net::HTTP's own default of 2s would reconnect between most calls.
      KEEP_ALIVE = 30

      @lock = Mutex.new
      @idle = Hash.new { |hash, key| hash[key] = [] }
      @pid  = Process.pid

      class << self
        # Sends a request over an idle connection to its host, or a new one.
        #
        # @param uri [URI] the URI for the HTTP request
        # @param req [Net::HTTPRequest] the request object
        # @param open_timeout [Numeric] the timeout for opening a connection
        # @param read_timeout [Numeric] the timeout for reading the response
        # @return [Net::HTTPResponse] the response, its body fully read
        def request(uri, req, open_timeout:, read_timeout:)
          key               = [uri.scheme, uri.hostname, uri.port]
          http              = checkout(key) || connect(uri)
          http.open_timeout = open_timeout
          http.read_timeout = read_timeout
          http.start unless http.started?

          response = http.request(req)
          Thread.handle_interrupt(Object => :never) do
            checkin(key, http)
            http = nil
          end
          response
        ensure
          discard(http) if http
        end

        # Closes every idle connection.
        #
        # @return [void]
        def clear
          connections = synchronize do
            all = @idle.values.flatten
            @idle.clear
            all
          end
          connections.each { |http| discard(http) }
        end

        private

        def connect(uri)
          Net::HTTP.new(uri.hostname, uri.port).tap do |http|
            http.use_ssl            = uri.scheme == 'https'
            http.keep_alive_timeout = KEEP_ALIVE
          end
        end

        def checkout(key)
          synchronize { @idle[key].pop }
        end

        def checkin(key, http)
          kept = synchronize { @idle[key].size < MAX_IDLE && @idle[key].push(http) }
          discard(http) unless kept
        end

        def discard(http)
          http.finish if http.started?
        rescue IOError, SystemCallError
          nil
        end

        # The parent's connections are dropped, not closed: closing them here
        # would shut sockets the parent may still be using.
        def synchronize(&block)
          reset_after_fork unless @pid == Process.pid
          @lock.synchronize(&block)
        end

        def reset_after_fork
          @lock = Mutex.new
          @idle = Hash.new { |hash, key| hash[key] = [] }
          @pid  = Process.pid
        end
      end
    end
  end
end

# frozen_string_literal: true

require 'net/http'
require 'json'
require 'openssl'
require 'uri'

require 'solace/errors'
require 'solace/utils/rpc_client'

module Solace
  # Connection to a Solana RPC node
  #
  # This class provides methods for sending JSON-RPC requests to a Solana RPC node and parsing responses.
  # It includes methods for sending transactions, getting account information, and getting blockhashes.
  #
  # @example
  #   # Initialize the connection
  #   connection = Solace::Connection.new('http://localhost:8899', commitment: 'confirmed')
  #
  #   # Get account information
  #   connection.get_account_info(account.address)
  #
  #   # Request an airdrop
  #   result = connection.request_airdrop(account.address, 1000000)
  #
  #   # Wait for the transaction to be finalized
  #   connection.wait_for_confirmed_signature('finalized') { result['result'] }
  #
  # @raise [
  #   Solace::Errors::HTTPError,
  #   Solace::Errors::ParseError,
  #   Solace::Errors::RPCError,
  #   Solace::Errors::ConfirmationTimeout
  # ]
  # @since 0.0.1
  # rubocop:disable Metrics/ClassLength
  class Connection
    # Commitment levels, lowest first
    COMMITMENTS = %w[processed confirmed finalized].freeze

    # A failure reported below this level may sit on a fork that gets dropped
    FINAL_FAILURE_LEVEL = COMMITMENTS.index('confirmed')

    # HTTP statuses a node or its provider answers while busy or briefly down:
    # 408 is the client's own timeout, 520-524 a Cloudflare-fronted origin that
    # is down or slow. 501 and 505 are permanent.
    TRANSIENT_HTTP_CODES = [408, 429, 500, 502, 503, 504, *520..524].freeze

    # HTTP statuses the wait backs off on: the node is throttling or failing
    BACKOFF_HTTP_CODES = (TRANSIENT_HTTP_CODES - [408]).freeze

    # Longest pause between polls while backing off, unless Retry-After asks for more
    MAX_BACKOFF_SECONDS = 2

    # Least time worth starting a poll with after the first: a shorter request
    # would mostly time out on its own cap
    MIN_POLL_SECONDS = 0.25

    # Solana RPC errors for a node that is behind: -32005 node unhealthy,
    # -32016 minimum context slot not reached
    TRANSIENT_RPC_CODES = [-32_005, -32_016].freeze

    # Network failures the RPC client lets through unwrapped
    TRANSIENT_NETWORK_ERRORS = [Errno::ECONNRESET, Errno::ECONNREFUSED, OpenSSL::SSL::SSLError].freeze

    # @!attribute [r] rpc_url
    #   The URL of the Solana RPC node
    attr_reader :rpc_client

    # @!attribute [r] default_options
    #   The default options for RPC requests
    attr_reader :default_options

    # Last fetched blockhash
    attr_reader :last_fetched_blockhash

    # Last fetched blockhash timestamp
    attr_reader :last_fetched_block_height

    # Initialize the connection with a default or custom RPC URL
    #
    # @param rpc_url [String] The URL of the Solana RPC node
    # @param commitment [String] The commitment level for RPC requests
    # @return [Solace::Connection] The connection object
    # @param [Integer] http_open_timeout The timeout for opening an HTTP connection
    # @param [Integer] http_read_timeout The timeout for reading an HTTP response
    # @param [String] encoding The encoding for the RPC requests
    def initialize(
      rpc_url = 'http://localhost:8899',
      commitment: 'processed',
      http_open_timeout: 30,
      http_read_timeout: 60,
      encoding: 'base64'
    )
      # Initialize the RPC client
      @rpc_client = Utils::RPCClient.new(
        rpc_url,
        open_timeout: http_open_timeout,
        read_timeout: http_read_timeout
      )

      # Set default options for rpc requests
      @default_options = {
        commitment: commitment,
        encoding:   encoding
      }
    end

    # Gets the version of the Solana node
    #
    # @return [Hash] The version information
    def get_version
      @rpc_client.rpc_request('getVersion')['result']
    end

    # Get the health status of the Solana node
    #
    # @return [String] The health status
    def get_health
      @rpc_client.rpc_request('getHealth')['result']
    end

    # Get the genesis hash of the Solana node
    #
    # @return [String] The genesis hash
    def get_genesis_hash
      @rpc_client.rpc_request('getGenesisHash')['result']
    end

    # Request an airdrop of lamports to a given address
    #
    # @param pubkey [String] The public key of the account to receive the airdrop
    # @param lamports [Integer] Amount of lamports to airdrop
    # @param [Hash{Symbol => Object}] options The options for the request
    # @return [String] The transaction signature of the airdrop
    def request_airdrop(pubkey, lamports, options = {})
      @rpc_client.rpc_request(
        'requestAirdrop',
        [
          pubkey,
          lamports,
          default_options.merge(options)
        ]
      )
    end

    # Build options for get_latest_blockhash
    #
    # @return [Hash{Symbol => Object}]
    def build_get_latest_blockhash_options
      {
        commitment: default_options[:commitment]
      }
    end

    # Get the latest blockhash from the Solana node
    #
    # Stores the last fetched blockhash and last valid block height in the connection, as
    # different clients may need to access these values.
    #
    # @example
    #  # Initialize the connection
    #  connection = Solace::Connection.new('http://localhost:8899', commitment: 'confirmed')
    #
    #  # Get the latest blockhash
    #  blockhash, last_valid_block_height = connection.get_latest_blockhash
    #
    #  puts "Latest blockhash: #{blockhash}"
    #  puts "Last valid block height: #{last_valid_block_height}"
    #
    #  # Access the last fetched blockhash and height from the connection
    #  puts "Stored blockhash: #{connection.last_fetched_blockhash}"
    #  puts "Stored last valid block height: #{connection.last_fetched_block_height}"
    #
    # @return [Array<String, Integer>] The latest blockhash and lastValidBlockHeight
    def get_latest_blockhash
      result = @rpc_client
               .rpc_request('getLatestBlockhash', [build_get_latest_blockhash_options])
               .dig('result', 'value')

      # Set the last fetched blockhash and last valid block height in the connection
      @last_fetched_blockhash, @last_fetched_block_height = result.values_at('blockhash', 'lastValidBlockHeight')

      # Return the blockhash and last valid block height
      [@last_fetched_blockhash, @last_fetched_block_height]
    end

    # Get the current block height from the Solana node
    #
    # Defaults to the connection's commitment so comparisons against the
    # +lastValidBlockHeight+ from {#get_latest_blockhash} stay consistent.
    #
    # @param commitment [String] The commitment level for the request
    # @return [Integer] The current block height
    def get_block_height(commitment: default_options[:commitment])
      @rpc_client.rpc_request('getBlockHeight', [{ commitment: commitment }])['result']
    end

    # Get the current slot from the Solana node
    #
    # @param commitment [String] The commitment level for the request
    # @return [Integer] The current slot
    #
    # @since 0.1.8
    def get_slot(commitment: default_options[:commitment])
      @rpc_client.rpc_request('getSlot', [{ commitment: commitment }])['result']
    end

    # Get the minimum required lamports for rent exemption
    #
    # @param space [Integer] Number of bytes to allocate for the account
    # @return [Integer] The minimum required lamports
    def get_minimum_lamports_for_rent_exemption(space)
      @rpc_client.rpc_request('getMinimumBalanceForRentExemption', [space])['result']
    end

    # Get the account information from the Solana node
    #
    # @param pubkey [String] The public key of the account
    # @return [Object] The account information
    def get_account_info(pubkey)
      @rpc_client.rpc_request('getAccountInfo', [pubkey, default_options]).dig('result', 'value')
    end

    # Get multiple accounts information from the Solana node
    #
    # @param pubkeys [Array<String>] The public keys of the accounts
    # @return [Array<Object>] The accounts information
    def get_multiple_accounts(pubkeys)
      @rpc_client.rpc_request('getMultipleAccounts', [pubkeys, default_options]).dig('result', 'value')
    end

    # Get the balance of a specific account
    #
    # @param pubkey [String] The public key of the account
    # @return [Integer] The balance of the account
    def get_balance(pubkey)
      @rpc_client.rpc_request('getBalance', [pubkey, default_options]).dig('result', 'value')
    end

    # Get the balance of a token account
    #
    # @param token_account [String] The public key of the token account
    # @return [Hash] Token account balance information with amount and decimals
    def get_token_account_balance(token_account)
      @rpc_client.rpc_request('getTokenAccountBalance', [token_account, default_options]).dig('result', 'value')
    end

    # Gets the token accounts by owner.
    #
    # Defaults to the legacy SPL Token program; pass
    # +token_program_id: Solace::Constants::TOKEN_2022_PROGRAM_ID+ for Token-2022.
    #
    # @param owner [String] The public key of the owner
    # @param token_program_id [String] The token program to filter by (defaults to legacy SPL Token)
    # @return [Array<Hash>] The token accounts owned by the owner under the given token program
    def get_token_accounts_by_owner(owner, token_program_id: Constants::TOKEN_PROGRAM_ID)
      params = [owner, { programId: token_program_id }, default_options]
      @rpc_client.rpc_request('getTokenAccountsByOwner', params).dig('result', 'value')
    end

    # Discovery-only helper: returns the program ID that owns a given mint.
    #
    # Use this to dispatch between {Constants::TOKEN_PROGRAM_ID} and
    # {Constants::TOKEN_2022_PROGRAM_ID} when the mint's program is not known
    # ahead of time. If you also need the rest of the mint's account data
    # (decimals, supply, ...), call {#get_account_info} directly and read
    # +'owner'+ yourself — calling both would cost two RPC roundtrips.
    #
    # @param mint [String] The mint address
    # @return [String, nil] The program ID that owns the mint, or +nil+ if the account does not exist
    def get_mint_program_id(mint)
      get_account_info(mint)&.dig('owner')
    end

    # Get the transaction by signature
    #
    # @param signature [String] The signature of the transaction
    # @return [Transaction] The transaction object
    # @param [Hash{Symbol => Object}] options
    def get_transaction(signature, options = { maxSupportedTransactionVersion: 0 })
      @rpc_client.rpc_request('getTransaction', [signature, default_options.merge(options)])['result']
    end

    # Get the signature status
    #
    # @param signatures [Array] The signatures of the transactions
    # @param timeout [Numeric, nil] caps the request's open and read timeouts
    # @return [Object] The signature status
    def get_signature_statuses(signatures, timeout: nil)
      @rpc_client.rpc_request('getSignatureStatuses',
                              [signatures, default_options.merge({ 'searchTransactionHistory' => true })],
                              timeout: timeout)['result']
    end

    # Get the program accounts
    #
    # @param program_id [String] The program ID
    # @param filters [Array] The filters
    # @return [Array] The program accounts
    # @param [Hash{Symbol => Object}] options
    def get_program_accounts(program_id, filters)
      @rpc_client.rpc_request('getProgramAccounts', [program_id, default_options.merge(filters: filters)])['result']
    end

    # Get the signature status
    #
    # @param signature [String] The signature of the transaction
    # @param timeout [Numeric, nil] caps the request's open and read timeouts
    # @return [Object] The signature status
    def get_signature_status(signature, timeout: nil)
      get_signature_statuses([signature], timeout: timeout)
    end

    # Builds send_transaction options
    #
    # @param overrides[Hash] The overrides for the options
    # @return [Hash] The options for the send_transaction call
    def build_send_transaction_options(overrides)
      {
        skipPreflight:       false,
        encoding:            default_options[:encoding],
        commitment:          default_options[:commitment],
        preflightCommitment: default_options[:commitment]
      }.merge(overrides)
    end

    # Send a transaction to the Solana node
    #
    # @param transaction [Transaction] The transaction to send
    # @param [Hash{Symbol => Object}] overrides
    # @return [String] The signature of the transaction
    def send_transaction(transaction, overrides = {})
      @rpc_client.rpc_request('sendTransaction', [transaction, build_send_transaction_options(overrides)])
    end

    # Simulate a transaction on the Solana node
    #
    # @param transaction [Transaction] The transaction to simulate
    # @param [Hash{Symbol => Object}] overrides
    # @return [Object] The result of the simulation
    def simulate_transaction(transaction, overrides = {})
      @rpc_client.rpc_request('simulateTransaction', [transaction, build_send_transaction_options(overrides)])
    end

    # Wait until the yielded signature reaches the desired commitment or timeout.
    #
    # A status at or above the desired commitment counts as reached, so waiting for
    # "confirmed" returns once the node reports "finalized". A failure at "confirmed"
    # or above is final and raises whatever commitment is awaited. A transient error
    # from a poll (see #transient_poll_error?) counts as not reached yet; any other
    # error raises at once. Each poll's request is bounded by the time left.
    #
    # @param commitment [String, Symbol] One of "processed", "confirmed", "finalized"
    # @param timeout [Numeric] seconds to wait before raising
    # @param interval [Numeric] polling interval in seconds
    # @yieldreturn [String, Hash] a signature string or a JSON-RPC hash with "result"
    # @return [String] the signature when the commitment is reached
    # @raise [ArgumentError] when no block is given or the commitment is unknown
    # @raise [Errors::TransactionFailed] when the transaction fails at "confirmed" or above
    # @raise [Errors::ConfirmationTimeout] when the commitment is not reached in time,
    #   with the last transient poll error as its cause
    def wait_for_confirmed_signature(
      commitment = 'confirmed',
      timeout: 60,
      interval: 0.1
    )
      raise ArgumentError, 'Block required' unless block_given?

      awaited   = awaited_level(commitment)
      signature = extract_signature_from(yield)

      last_error = poll_until(monotonic_deadline(timeout), interval) do |time_left|
        return signature if commitment_reached?(signature, awaited, time_left)
      end

      raise Errors::ConfirmationTimeout.format(signature, COMMITMENTS[awaited], timeout, last_error), cause: last_error
    end

    private

    # The awaited commitment as an index in COMMITMENTS
    #
    # @param commitment [String, Symbol] The commitment level awaited
    # @return [Integer] The level
    # @raise [ArgumentError] when the commitment is unknown
    def awaited_level(commitment)
      COMMITMENTS.index(commitment.to_s) or raise ArgumentError, "Unknown commitment: #{commitment}"
    end

    # Confirms the commitment is reached: the node reports the signature at the
    # commitment or a higher one, and the transaction succeeded.
    #
    # @param signature [String] The signature of the transaction
    # @param awaited [Integer] The awaited commitment's index in COMMITMENTS
    # @param time_left [Numeric] Seconds the poll's request may take
    # @return [Boolean] Whether the commitment is reached
    # @raise [Errors::TransactionFailed] when the transaction failed at "confirmed" or above
    def commitment_reached?(signature, awaited, time_left)
      status = get_signature_status(signature, timeout: time_left).dig('value', 0)
      level  = status && reported_level(status)
      return false unless level
      return level >= awaited unless status['err']
      return false if level < FINAL_FAILURE_LEVEL

      raise Errors::TransactionFailed.format(signature, COMMITMENTS[awaited], COMMITMENTS[level], status['err'])
    end

    # The status's commitment as an index in COMMITMENTS
    #
    # @param status [Hash] One entry of a getSignatureStatuses result
    # @return [Integer, nil] The level, or nil when the status names none
    def reported_level(status)
      return COMMITMENTS.index('finalized') if rooted?(status)

      COMMITMENTS.index(status['confirmationStatus'])
    end

    # A status with no confirmationStatus and no confirmations count, each null
    # or absent, is for a rooted transaction
    #
    # @param status [Hash] One entry of a getSignatureStatuses result
    # @return [Boolean] Whether the status is for a rooted transaction
    def rooted?(status)
      status['confirmationStatus'].nil? && status['confirmations'].nil?
    end

    # Whether an error from one poll may clear by the next: a busy or briefly
    # unreachable node, or a maintenance page in place of JSON
    #
    # @param error [StandardError] The error the poll raised
    # @return [Boolean] Whether to keep polling
    def transient_poll_error?(error)
      case error
      when Errors::HTTPError then TRANSIENT_HTTP_CODES.include?(error.code)
      when Errors::RPCError then TRANSIENT_RPC_CODES.include?(error.rpc_code)
      when Errors::ParseError then error.body.to_s.lstrip.start_with?('<')
      else TRANSIENT_NETWORK_ERRORS.any? { |transient| error.is_a?(transient) }
      end
    end

    # Extracts signature from given value
    #
    # @param value [String, Object] The result of the yielded block
    # @return [String] The signature
    def extract_signature_from(value)
      value.is_a?(String) ? value : value['result']
    end

    # Calls the block once per poll until the deadline, with the seconds left for
    # the poll's request. The first poll always runs; a later one only with at
    # least MIN_POLL_SECONDS left. Between polls it sleeps the interval, or backs
    # off while the node throttles or fails, but never past the deadline. A
    # transient error from the block counts as one poll; any other error raises.
    #
    # @param deadline [Float] The deadline for the timeout
    # @param interval [Numeric] The polling interval in seconds
    # @yieldparam time_left [Float] Seconds left before the deadline
    # @return [StandardError, nil] The last transient error a poll raised, unless
    #   it was a timeout the poll's own cap caused
    def poll_until(deadline, interval, &poll)
      last_error = nil
      backoff    = interval
      time_left  = seconds_until(deadline)

      while time_left.positive?
        error          = transient_error_from(time_left, &poll)
        last_error     = error unless error.nil? || capped_timeout?(error, time_left)
        pause, backoff = pause_after(error, interval, backoff)

        sleep [pause, seconds_until(deadline)].min.clamp(0..)
        time_left = seconds_until(deadline)
        break if time_left < MIN_POLL_SECONDS
      end

      last_error
    end

    # Runs one poll
    #
    # @param time_left [Float] Seconds left before the deadline
    # @return [StandardError, nil] The transient error the poll raised, if any
    # @raise [StandardError] any error that is not transient
    def transient_error_from(time_left)
      yield time_left
      nil
    rescue StandardError => e
      raise unless transient_poll_error?(e)

      e
    end

    # Whether a timeout may come from the cap the wait put on the poll's request
    # rather than from the node: the cap was below a timeout the client sets
    #
    # @param error [StandardError] The error the poll raised
    # @param time_left [Float] The cap the poll's request was given
    # @return [Boolean] Whether the timeout is the wait's own
    def capped_timeout?(error, time_left)
      error.is_a?(Errors::HTTPError) && error.code == 408 &&
        time_left < [@rpc_client.open_timeout, @rpc_client.read_timeout].max
    end

    # The pause before the next poll, and the backoff after it: Retry-After or
    # the backoff, doubling up to MAX_BACKOFF_SECONDS, while the node throttles or
    # fails; the interval otherwise
    #
    # @param error [StandardError, nil] The transient error the poll raised
    # @param interval [Numeric] The polling interval in seconds
    # @param backoff [Numeric] The current backoff in seconds
    # @return [Array(Numeric, Numeric)] The pause and the next backoff
    def pause_after(error, interval, backoff)
      return [interval, interval] unless error.is_a?(Errors::HTTPError) && BACKOFF_HTTP_CODES.include?(error.code)

      [error.retry_after || backoff, [backoff * 2, MAX_BACKOFF_SECONDS].min]
    end

    # Seconds left before a deadline, negative once it has passed
    #
    # @param deadline [Float] The deadline for the timeout
    # @return [Float] The seconds left
    def seconds_until(deadline)
      deadline - Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end

    # Sets a deadline given a timeout in seconds
    #
    # @param seconds [Integer] The seconds for the deadline
    # @return [Integer] The deadline in seconds
    def monotonic_deadline(seconds)
      Process.clock_gettime(Process::CLOCK_MONOTONIC) + seconds
    end
  end
  # rubocop:enable Metrics/ClassLength
end

# frozen_string_literal: true

require 'net/http'
require 'json'
require 'uri'

module Solace
  # !@class Connection
  #
  # A class representing a connection to a Solana RPC node. Handles sending JSON-RPC requests and parsing responses.
  #
  # @return [Class]
  #
  # rubocop:disable Metrics/ClassLength
  class Connection
    # @!attribute [r] rpc_url
    #   The URL of the Solana RPC node
    #
    # @return [String] The URL of the Solana RPC node
    attr_reader :rpc_url

    # @!attribute [r] default_options
    #   The default options for RPC requests
    #
    # @return [Hash] The default options for RPC requests
    attr_reader :default_options

    # Initialize the connection with a default or custom RPC URL
    #
    # @param rpc_url [String] The URL of the Solana RPC node
    # @return [Solace::Connection] The connection object
    # @param [String] commitment
    def initialize(rpc_url = 'http://localhost:8899', commitment: 'confirmed')
      @request_id = nil
      @rpc_url = rpc_url

      # Set default options
      @default_options = {
        commitment: commitment,
        encoding: 'base64'
      }
    end

    # Sends a JSON-RPC request to the configured Solana RPC server.
    #
    # @param method [String] the JSON-RPC method name
    # @param params [Array] the parameters for the RPC method
    # @return [Hash] the parsed JSON response
    # @raise [RuntimeError] if the response is not successful
    def rpc_request(method, params = [])
      request = build_rpc_request(method, params)
      response = perform_http_request(request)
      handle_rpc_response(response)
    end

    # Request an airdrop of lamports to a given address
    #
    # @param pubkey [String] The public key of the account to receive the airdrop
    # @param lamports [Integer] Amount of lamports to airdrop
    # @return [String] The transaction signature of the airdrop
    # @param [Hash{Symbol => Object}] options
    def request_airdrop(pubkey, lamports, options = {})
      rpc_request(
        'requestAirdrop',
        [
          pubkey,
          lamports,
          default_options.merge(options)
        ]
      )
    end

    # Get the latest blockhash from the Solana node
    #
    # @return [String] The latest blockhash
    def get_latest_blockhash
      rpc_request('getLatestBlockhash')['result']['value']['blockhash']
    end

    # Get the minimum required lamports for rent exemption
    #
    # @param space [Integer] Number of bytes to allocate for the account
    # @return [Integer] The minimum required lamports
    def get_minimum_lamports_for_rent_exemption(space)
      rpc_request('getMinimumBalanceForRentExemption', [space])['result']
    end

    # Get the account information from the Solana node
    #
    # @param pubkey [String] The public key of the account
    # @return [Object] The account information
    def get_account_info(pubkey)
      response = rpc_request(
        'getAccountInfo',
        [
          pubkey,
          default_options
        ]
      )['result']

      return if response.nil?

      response['value']
    end

    # Get the balance of a specific account
    #
    # @param pubkey [String] The public key of the account
    # @return [Integer] The balance of the account
    def get_balance(pubkey)
      rpc_request(
        'getBalance',
        [
          pubkey,
          default_options
        ]
      )['result']['value']
    end

    # Get the balance of a token account
    #
    # @param token_account [String] The public key of the token account
    # @return [Hash] Token account balance information with amount and decimals
    def get_token_account_balance(token_account)
      rpc_request(
        'getTokenAccountBalance',
        [
          token_account,
          default_options
        ]
      )['result']['value']
    end

    # Get the transaction by signature
    #
    # @param signature [String] The signature of the transaction
    # @return [Solace::Transaction] The transaction object
    # @param [Hash{Symbol => Object}] options
    def get_transaction(signature, options = { maxSupportedTransactionVersion: 0 })
      rpc_request(
        'getTransaction',
        [
          signature,
          default_options.merge(options)
        ]
      )['result']
    end

    # Get the signature status
    #
    # @param signatures [Array] The signatures of the transactions
    # @return [Object] The signature status
    def get_signature_status(signatures)
      rpc_request(
        'getSignatureStatuses',
        [
          signatures,
          default_options.merge({ 'searchTransactionHistory' => true })
        ]
      )['result']
    end

    # Send a transaction to the Solana node
    #
    # @param transaction [Solace::Transaction] The transaction to send
    # @return [String] The signature of the transaction
    # @param [Hash{Symbol => Object}] options
    def send_transaction(transaction, options = {})
      rpc_request(
        'sendTransaction',
        [
          transaction,
          default_options.merge(options)
        ]
      )
    end

    # Wait for a confirmed signature from the transaction
    #
    # @param commitment [String] The commitment level to wait for
    # @return [Boolean] True if the transaction was confirmed, false otherwise
    def wait_for_confirmed_signature(commitment = 'confirmed')
      raise ArgumentError, 'Block required' unless block_given?

      # Get the signature from the block
      signature = yield

      interval = 0.1

      # Wait for confirmation
      loop do
        status = get_signature_status([signature]).dig('value', 0)

        break if status && status['confirmationStatus'] == commitment

        sleep interval
      end

      signature
    end

    private

    def build_rpc_request(method, params)
      uri = URI(rpc_url)
      req = Net::HTTP::Post.new(uri)
      req['Accept'] = 'application/json'
      req['Content-Type'] = 'application/json'
      @request_id = SecureRandom.uuid

      req.body = {
        jsonrpc: '2.0',
        id: @request_id,
        method: method,
        params: params
      }.to_json

      [uri, req]
    end

    def perform_http_request((uri, req))
      Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
        http.request(req)
      end
    end

    def handle_rpc_response(response)
      raise "RPC error: #{response.body}" unless response.is_a?(Net::HTTPSuccess)

      JSON.parse(response.body)
    end
  end
  # rubocop:enable Metrics/ClassLength
end

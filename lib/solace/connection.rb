# frozen_string_literal: true

require 'net/http'
require 'json'
require 'uri'

module Solace
  class Connection
    attr_reader :rpc_url

    # !const default options
    DEFAULT_OPTIONS = {
      encoding: 'base64',
      commitment: 'confirmed'
    }.freeze

    # Initialize the connection with a default or custom RPC URL
    #
    # @param rpc_url [String] The URL of the Solana RPC node
    # @return [Solace::Connection] The connection object
    def initialize(rpc_url = 'http://localhost:8899')
      @rpc_url = rpc_url
      @request_id = nil
    end

    # Make an RPC request to the Solana node
    #
    # @param method [String] The RPC method to call
    # @param params [Array] Parameters for the RPC method
    # @return [Object] Result of the RPC call
    def rpc_request(method, params = [])
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

      res = Net::HTTP.start(
        uri.hostname,
        uri.port,
        use_ssl: uri.scheme == 'https'
      ) do |http|
        http.request(req)
      end

      raise "RPC error: #{res.body}" unless res.is_a?(Net::HTTPSuccess)

      JSON.parse(res.body)
    end

    # Request an airdrop of lamports to a given address
    #
    # @param pubkey [String] The public key of the account to receive the airdrop
    # @param lamports [Integer] Amount of lamports to airdrop
    # @return [String] The transaction signature of the airdrop
    def request_airdrop(pubkey, lamports, options = {})
      rpc_request(
        'requestAirdrop',
        [
          pubkey,
          lamports,
          DEFAULT_OPTIONS.merge(options)
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
          DEFAULT_OPTIONS
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
          DEFAULT_OPTIONS
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
          DEFAULT_OPTIONS
        ]
      )['result']['value']
    end

    # Get the transaction by signature
    #
    # @param signature [String] The signature of the transaction
    # @return [Solace::Transaction] The transaction object
    def get_transaction(signature, options = { maxSupportedTransactionVersion: 0 })
      rpc_request(
        'getTransaction',
        [
          signature,
          DEFAULT_OPTIONS.merge(options)
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
          DEFAULT_OPTIONS.merge({ 'searchTransactionHistory' => true })
        ]
      )['result']
    end

    # Send a transaction to the Solana node
    #
    # @param transaction [Solace::Transaction] The transaction to send
    # @return [String] The signature of the transaction
    def send_transaction(transaction, options = {})
      rpc_request(
        'sendTransaction',
        [
          transaction,
          DEFAULT_OPTIONS.merge(options)
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

      # Wait for confirmation
      loop do
        status = get_signature_status([signature]).dig('value', 0)

        break if status && status['confirmationStatus'] == commitment

        sleep 0.5
      end

      signature
    end
  end
end

# frozen_string_literal: true

require 'net/http'
require 'json'
require 'uri'

class Solana::Connection
  attr_reader :rpc_url

  # Initialize the connection with a default or custom RPC URL
  # 
  # @param rpc_url [String] The URL of the Solana RPC node
  # @return [Solana::Connection] The connection object
  def initialize(rpc_url = "http://localhost:8899")
    @rpc_url = rpc_url
    @request_id = 0
  end

  # Make an RPC request to the Solana node
  # 
  # @param method [String] The RPC method to call
  # @param params [Array] Parameters for the RPC method
  # @return [Object] Result of the RPC call
  def rpc_request(method, params = [])
    uri = URI(rpc_url)
    req = Net::HTTP::Post.new(uri)
    req["Content-Type"] = "application/json"
    @request_id += 1
    req.body = {
      jsonrpc: "2.0",
      id: @request_id,
      method: method,
      params: params
    }.to_json

    res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
      http.request(req)
    end
    raise "RPC error: #{res.body}" unless res.is_a?(Net::HTTPSuccess)
    puts "RPC response: #{res.body}"
    JSON.parse(res.body)["result"]
  end

  # Get the latest blockhash from the Solana node
  # 
  # @return [String] The latest blockhash
  def get_latest_blockhash
    rpc_request("getLatestBlockhash")["value"]["blockhash"]
  end

  # Get the balance of a specific account
  # 
  # @param pubkey [String] The public key of the account
  # @return [Integer] The balance of the account
  def get_balance(pubkey)
    rpc_request("getBalance", [pubkey])["value"]
  end

  # Send a transaction to the Solana node
  # 
  # @param transaction [Solana::Transaction] The transaction to send
  # @return [String] The signature of the transaction
  def send_transaction(transaction, options = {})
    rpc_request("sendTransaction", [transaction, { encoding: "base64" }.merge(options)])
  end
end


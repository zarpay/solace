# encoding: ASCII-8BIT  

require 'uri'
require 'json'
require 'net/http'

# =============================
# 🧩 Helper: Post Request
# =============================
def send_request(body)
  uri = URI("https://api.devnet.solana.com")
  http = Net::HTTP.new(uri.host, uri.port)
  req = Net::HTTP::Post.new(uri)
  http.use_ssl = true
  req["Content-Type"] = "application/json"
  req.body = body.to_json
  response = http.request(req)
  JSON.parse(response.body)
end

# =============================
# 🧩 Get Transaction
# =============================
signature = "3mFYAed6XS1K6YjhJWsaFykwiHkuvqNH2ZPyvnz2vZTa3Lftm2GMifzty5izw3biCMe8smWnTjxyCfkJEjEJM79G"

response = send_request({
  id: 1,
  jsonrpc: "2.0",
  method: "getTransaction",
  params: [
    signature,
    { 
      encoding: "base64",
      maxSupportedTransactionVersion: 0
    }
  ]
})

puts "Response:"
puts response


require 'net/http'
require 'json'

def find_versioned_transaction(address, limit = 100)
  uri = URI("https://api.mainnet-beta.solana.com")
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  req = Net::HTTP::Post.new(uri)
  req["Content-Type"] = "application/json"
  req.body = {
    jsonrpc: "2.0",
    id: 1,
    method: "getSignaturesForAddress",
    params: [address, {limit: limit}]
  }.to_json
  signatures = JSON.parse(http.request(req).body)["result"].map { |x| x["signature"] }

  signatures.each do |sig|
    req.body = {
      jsonrpc: "2.0",
      id: 1,
      method: "getTransaction",
      params: [sig, {encoding: "base64", maxSupportedTransactionVersion: 0}]
    }.to_json
    res = JSON.parse(http.request(req).body)["result"]
    next unless res

    puts "Found versioned transaction!"
    puts "Signature: #{sig}"
    puts "Base64: #{res["transaction"][0]}"
  end
  puts "No versioned transaction found in last #{limit} for #{address}"
  nil
end

# Example: use a busy address like Jupiter aggregator or a popular token mint.
find_versioned_transaction("JUP4Fb2cqiRUcaTHdrPC8h2gNsA2ETXiPDD33WcGuJB")
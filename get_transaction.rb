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
signature = "6aJZ6qyKT5Y1hjhV2ggQo8Ajmjvuponnz6rZ8qjhtbrE2SPirnEAZM5TShd24qxCp1oXmHPzVwMYeaSMbMcCPmM"

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

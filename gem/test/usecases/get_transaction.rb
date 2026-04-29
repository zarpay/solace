# frozen_string_literal: true

require 'test_helper'

# =============================
# 🧩 Get Transaction
# =============================
signature = '4yEs446FfgW5VZKa3GW4Ss1o19MUmE9QTqFnSpE3m96nbownfQh8RPvinj3batwVPwRsr2CcN7ipUJc8QypD2fgC'

response = Solace::Connection.new('https://api.mainnet-beta.solana.com').get_transaction(signature)

puts 'Response:'
puts response

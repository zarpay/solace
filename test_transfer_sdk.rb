# test_transfer.rb

require_relative 'lib/solana'
require 'base58'

bob = JSON.load_file('bob.json')
anna = JSON.load_file('anna.json')

# 1. Generate sender and recipient keypairs
sender = Solace::Keypair.from_secret_key(bob)
recipient = Solace::Keypair.from_secret_key(anna)

# 2. Connect to local validator
conn = Solace::Connection.new

# 3. Print initial balances
sender_balance = conn.get_balance(sender.address)
recipient_balance = conn.get_balance(recipient.address)

puts "Sender balance: #{sender_balance} lamports"
puts "Recipient balance: #{recipient_balance} lamports"

# 4. Build instruction
instruction = Solace::Instructions::TransferInstruction.build(
  to_index: 1,
  from_index: 0,
  program_index: 2,
  lamports: 10_000_000 # 0.01 SOL
)

# 5. Build message
message = Solace::Message.new(
  header: [
    1, # num_required_signatures
    0, # num_readonly_signed
    1  # num_readonly_unsigned
  ],
  accounts: [
    sender.address,
    recipient.address,
    Solace::Constants::SYSTEM_PROGRAM_ID
  ],
  recent_blockhash: conn.get_latest_blockhash,
  instructions: [instruction]
)

# 6. Build transaction
transaction = Solace::Transaction.new(message: message)

# 7. Sign transaction
transaction.sign(sender)

# 8. Send transaction
result = conn.send_transaction(transaction.serialize)

puts "Transaction sent: #{result}"

# 9. Print final balances
puts "Sender balance after: #{`solana balance #{sender.address}`}"
puts "Recipient balance after: #{`solana balance #{recipient.address}`}"

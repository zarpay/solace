# frozen_string_literal: true

# test_token_transfer_sdk.rb

require 'test_helper'
require 'base58'
require_relative '../../lib/solace/instructions/transfer_checked_instruction'

# TODO: Implement these helpers in your SDK for full SPL token support:
# - Solace::SPL.create_mint
# - Solace::SPL.create_associated_token_account
# - Solace::SPL.mint_to

bob = JSON.load_file(File.expand_path('../fixtures/bob.json', __dir__))
anna = JSON.load_file(File.expand_path('../fixtures/anna.json', __dir__))

sender = Solace::Keypair.from_secret_key(bob.pack('C*'))
Solace::Keypair.from_secret_key(anna.pack('C*'))

conn = Solace::Connection.new

# Use pre-created mint and token accounts (set these as environment variables or constants)
mint = '5TdHBognPcuumzVbcp6SfqDbkceGLAGbNYfP4yXpVJPA'
sender_token_account = 'HE4UYNGU19nxrVr4hzq1HQDn45A8QRmMX1gJubVHq8Vz'
recipient_token_account = 'D2t6jATJHqpAAH46XAmL7JHThGWqv56Lz8AiPwhT1Mez'

# Optionally, print these for debugging
puts "Mint: #{mint}"

puts 'Sender token balance before:'
puts `spl-token balance --owner ./test/fixtures/bob.json #{mint}`

puts 'Recipient token balance before:'
puts `spl-token balance --owner ./test/fixtures/anna.json #{mint}`

# 5. Build SPL token transfer instruction
instruction = Solace::Instructions::SplToken::TransferCheckedInstruction.build(
  amount: 100,
  decimals: 6,
  from_index: 1,      # sender_token_account
  to_index: 2,        # recipient_token_account
  authority_index: 0, # sender (authority)
  mint_index: 3,      # mint
  program_index: 4    # SPL Token program
)

# 6. Build transaction
accounts = [
  sender.address,
  sender_token_account,
  recipient_token_account,
  mint,
  Solace::Constants::TOKEN_PROGRAM_ID
]

message = Solace::Message.new(
  header: [
    1, # num_required_signatures
    0, # num_readonly_signed
    2 # num_readonly_unsigned
  ],
  accounts: accounts,
  recent_blockhash: conn.get_latest_blockhash[0],
  instructions: [instruction]
)

# 7. Build transaction
transaction = Solace::Transaction.new(message: message)
transaction.sign(sender)

# 8. Send transaction
result = conn.send_transaction(transaction.serialize)
puts "Token transfer transaction sent: #{result}"

# test_token_transfer_sdk.rb

require 'test_helper'
require 'base58'
require_relative '../../lib/solace/instructions/initialize_mint_instruction'

mint_authority = JSON.load_file(File.expand_path("../fixtures/mint-authority.json", __dir__))
mint_authority_keypair = Solace::Keypair.from_secret_key(mint_authority.pack('C*'))

conn = Solace::Connection.new

mint_keypair = Solace::Keypair.generate

# 5. Build SPL token transfer instruction
instruction = Solace::Instructions::InitializeMintInstruction.build(
  decimals: 6,
  mint_authority: mint_authority_keypair.public_key_bytes,
  rent_sysvar_index: 1,
  mint_account_index: 0,
  program_index: 2
)

# 6. Build transaction
accounts = [
  mint_keypair.address,
  Solace::Constants::SYSVAR_RENT_PROGRAM_ID,
  Solace::Constants::TOKEN_PROGRAM_ID
]

message = Solace::Message.new(
  header: [
    1, # num_required_signatures
    0, # num_readonly_signed
    2, # num_readonly_unsigned
  ],
  accounts: accounts,
  recent_blockhash: conn.get_latest_blockhash,
  instructions: [instruction]
)

# 7. Build transaction
transaction = Solace::Transaction.new(message: message)
transaction.sign(mint_keypair)

# 8. Send transaction
result = conn.send_transaction(transaction.serialize)
puts "Token transfer transaction sent: #{result}"



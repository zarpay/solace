# encoding: ASCII-8BIT
# frozen_string_literal: true

require 'base64'
require 'rbnacl'
require 'base58'
require 'stringio'

require 'test_helper'

# --- Script Execution ---

# 2. Setup
puts '--- Step 1: Setup ---'
# The payer is the account that will pay for the transaction fees and rent.
# It's loaded from fixtures in test_helper.rb
payer = Fixtures.load_keypair('payer')
puts "✅ Payer Account: #{payer.address}"

# A new keypair is generated for the new mint account. This account will hold
# information about the token, such as its supply and decimals.
mint_keypair = Solace::Keypair.generate
puts "✅ New Mint Account: #{mint_keypair.address}"

# The connection to the Solana cluster (devnet by default).
# It's loaded from test_helper.rb
conn = Solace::Connection.new
puts "✅ Connected to cluster: #{conn.rpc_url}"
puts "-----------------------\n"

# 3. Build Instructions
puts '--- Step 2: Building Instructions ---'
# We need the cost (in lamports) to make the new mint account rent-exempt.
# The size of a mint account is 82 bytes.
rent_lamports = conn.get_minimum_lamports_for_rent_exemption(82)
puts "✅ Rent for 82 bytes: #{rent_lamports} lamports"

# Instruction 1: Create a new account for the mint.
create_account_ix = Solace::Instructions::SystemProgram::CreateAccountInstruction.build(
  from_index: 0, # The payer is the first account
  new_account_index: 1, # The new mint is the second account
  system_program_index: 4, # The System Program is the fourth account
  lamports: rent_lamports,
  space: 82,
  owner: Solace::Constants::TOKEN_PROGRAM_ID
)
puts '✅ Built SystemProgram::CreateAccount instruction'

# Instruction 2: Initialize the new account as a mint.
initialize_mint_ix = Solace::Instructions::SplToken::InitializeMintInstruction.build(
  mint_account_index: 1, # The new mint is the second account
  rent_sysvar_index: 2, # The Rent Sysvar is the third account
  program_index: 3, # The SPL Token Program is the fourth account
  decimals: 6,
  mint_authority: payer.address # The payer will also be the mint authority
)
puts "\xE2\x9C\x85 Built SPLToken::InitializeMint instruction"
puts "-------------------------------------\n"

# 4. Build and Sign Transaction
puts '--- Step 3: Building and Signing Transaction ---'
# Create a new message and add the instructions.
message = Solace::Message.new(
  instructions: [create_account_ix, initialize_mint_ix],
  # Define all the accounts that will be used in the transaction.
  # Order matters for the instruction indices.
  accounts: [
    payer.address,
    mint_keypair.address,
    Solace::Constants::SYSVAR_RENT_PROGRAM_ID,
    Solace::Constants::TOKEN_PROGRAM_ID,
    Solace::Constants::SYSTEM_PROGRAM_ID
  ],
  # Set the message header now that we know the accounts.
  # Signers: payer (writable), mint_keypair (writable)
  # Read-only: Rent Sysvar, SPL Token Program, System Program
  header: [2, 0, 3],
  recent_blockhash: conn.get_latest_blockhash
)
puts '✅ Assembled message'

# Create the transaction with the message.
tx = Solace::Transaction.new(message: message)

# Sign the transaction with the required keypairs.
# The payer signs to authorize the lamport transfer.
# The mint_keypair signs because it's a new account being created.
tx.sign(payer, mint_keypair)
puts '✅ Signed transaction with payer and mint keypair'
puts "----------------------------------------------\n"

# 5. Send and Confirm Transaction
puts '--- Step 4: Sending Transaction ---'
signature = nil

# Serialize the transaction and send it to the cluster.
# Wait for the transaction to be confirmed.
conn.wait_for_confirmed_signature do
  signature = conn.send_transaction(tx.serialize)['result']
end

puts "\xE2\x9C\x85 Transaction confirmed!"
puts "View on Solana Explorer: https://explorer.solana.com/tx/#{signature}?cluster=devnet"
puts "---------------------------------\n"

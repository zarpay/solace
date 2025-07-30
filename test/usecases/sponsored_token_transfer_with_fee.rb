# frozen_string_literal: true

require 'test_helper'

# 1. Setup
puts '--- Step 1: Setup ---'

# The payer is the account that will pay for the transaction fees and rent.
# It's loaded from fixtures in test_helper.rb
payer = Fixtures.load_keypair('payer')
puts "✅ Payer Account: #{payer.address}"

# The mint is the account that holds information about the token, such as its supply and decimals.
mint = Fixtures.load_keypair('mint')
puts "✅ Mint Account: #{mint.address}"

# The connection to the Solana cluster (devnet by default).
# It's loaded from test_helper.rb
conn = Solace::Connection.new
puts "✅ Connected to cluster: #{conn.rpc_url}"

ata_program = Solace::Programs::AssociatedTokenAccount.new(connection: conn)

# Source and destination account owners and their associated token accounts for the loaded mint.
source_owner = Fixtures.load_keypair('bob')
destination_owner = Fixtures.load_keypair('anna')
fee_collector = Fixtures.load_keypair('fee-collector')

# Get or create associated token accounts
source_ata, = ata_program.get_or_create_address(
  owner: source_owner,
  mint: mint.address,
  payer: payer
)

destination_ata, = ata_program.get_or_create_address(
  owner: destination_owner,
  mint: mint.address,
  payer: payer
)

fee_collector_ata, = ata_program.get_or_create_address(
  owner: fee_collector,
  mint: mint.address,
  payer: payer
)

# Get token account balances
source_ata_start_balance = conn.get_token_account_balance(source_ata)
destination_ata_start_balance = conn.get_token_account_balance(destination_ata)
fee_collector_ata_start_balance = conn.get_token_account_balance(fee_collector_ata)

# 2. Build Instructions
puts '--- Step 2: Building Instructions ---'

# Amount to transfer
transfer_amount = 100_000_000

# Fee collected by the payer
fee_amount = transfer_amount * 0.01

# Accounts
accounts = [
  payer.address,
  source_owner.address,
  source_ata,
  destination_ata,
  fee_collector_ata,
  Solace::Constants::TOKEN_PROGRAM_ID
]

# Instruction for transferring tokens
transfer_ix = Solace::Instructions::SplToken::TransferInstruction.build(
  amount: transfer_amount,
  owner_index: 1,
  source_index: 2,
  destination_index: 3,
  program_index: 5
)

# Instruction for collecting fee
fee_ix = Solace::Instructions::SplToken::TransferInstruction.build(
  amount: fee_amount,
  owner_index: 1,
  source_index: 2,
  destination_index: 4,
  program_index: 5
)

# 3. Prepare the transaction
puts '--- Step 3: Preparing Transaction ---'

# Message
message = Solace::Message.new(
  header: [2, 0, 1],
  accounts: accounts,
  instructions: [transfer_ix, fee_ix],
  recent_blockhash: conn.get_latest_blockhash
)

# Transaction
tx = Solace::Transaction.new(message: message)

# 4. Sign and send the transaction
puts '--- Step 4: Signing and Sending Transaction ---'
tx.sign(payer, source_owner)

response = conn.send_transaction(tx.serialize)
conn.wait_for_confirmed_signature { response['result'] }

# 5. Print final balances
puts '--- Step 5: Printing Final Balances ---'

source_ata_end_balance = conn.get_token_account_balance(source_ata)
destination_ata_end_balance = conn.get_token_account_balance(destination_ata)
fee_collector_ata_end_balance = conn.get_token_account_balance(fee_collector_ata)

puts "
✅ Fee Collector's account:
- Primary: #{fee_collector.address}
- ATA: #{fee_collector_ata}
- Start Token Balance: #{fee_collector_ata_start_balance['uiAmountString']}
- End Token Balance: #{fee_collector_ata_end_balance['uiAmountString']}

✅ Bobs's account:
- Primary: #{source_owner.address}
- ATA: #{source_ata}
- Start Token Balance: #{source_ata_start_balance['uiAmountString']}
- End Token Balance: #{source_ata_end_balance['uiAmountString']}

✅ Annas's account:
- Primary: #{destination_owner.address}
- ATA: #{destination_ata}
- Start Token Balance: #{destination_ata_start_balance['uiAmountString']}
- End Token Balance: #{destination_ata_end_balance['uiAmountString']}
"

# frozen_string_literal: true

# test/bootstrap.rb

# Bootstraps the test environment with a Solana test validator and some pre-funded accounts.

require 'tty-spinner'

require 'minitest/mock'
require 'minitest/autorun'
require 'minitest/hooks/default'

require 'solace'

require_relative 'support/fixtures'
require_relative 'support/factory_bot'
require_relative 'support/solana_test_validator'

# Make it less boring to run tasks
def with_spinner(message)
  spinner = TTY::Spinner.new("⤷ [:spinner] #{message}", format: :dots)
  spinner.auto_spin
  yield
  spinner.success('(Done)')
end

# Make sure keypairs are loaded
bob = Fixtures.load_keypair('bob')
anna = Fixtures.load_keypair('anna')
payer = Fixtures.load_keypair('payer')

mint = Fixtures.load_keypair('mint')
mint_authority = Fixtures.load_keypair('mint-authority')

fee_collector = Fixtures.load_keypair('fee-collector')

# Make sure connection is loaded
rpc_url = 'http://localhost:8899'
connection = Solace::Connection.new(rpc_url, commitment: 'finalized')

spl_token_program = Solace::Programs::SplToken.new(connection: connection)
ata_program = Solace::Programs::AssociatedTokenAccount.new(connection: connection)

# Amounts to airdrop
TOKENS_AIRDROP = 10_000_000
LAMPORTS_AIRDROP = 10_000_000_000
SETUP_PAYER_AIRDROP = 100_000_000_000

puts 'Bootstrapping:'
setup_payer = Solace::Keypair.generate

puts "\n============= Funding Setup Payer (Bootstrap Only) ==============="
with_spinner("Airdropping #{SETUP_PAYER_AIRDROP / 1_000_000_000} SOL to setup payer") do
  result = connection.request_airdrop(setup_payer.address, SETUP_PAYER_AIRDROP)
  connection.wait_for_confirmed_signature('finalized') { result['result'] }
end

# Accounts to fund
fixture_accounts = [
  {
    name: 'payer',
    keypair: payer
  },
  {
    name: 'bob',
    keypair: bob
  },
  {
    name: 'anna',
    keypair: anna
  },
  {
    name: 'mint-authority',
    keypair: mint_authority
  },
  {
    name: 'fee-collector',
    keypair: fee_collector
  }
]

# Composer for setting up all fixture accounts
setup_composer = Solace::TransactionComposer.new(connection: connection)

fixture_accounts.map do |account|
  # Extract name and keypair from account hash
  name, keypair = account.values_at(:name, :keypair)

  ata_address = ata_program.get_address(owner: keypair, mint: mint).first
  ata_exists  = !connection.get_account_info(ata_address).nil?

  puts "\n============= Setting Up #{name.capitalize} ==============="
  puts "⤷ Address: #{keypair.address}"
  puts "⤷ #{ata_exists ? 'Existing' : 'Creating'} ATA at #{ata_address}"
  puts "⤷ Airdropping #{LAMPORTS_AIRDROP / 1_000_000_000} SOL and #{TOKENS_AIRDROP} tokens"

  # Give the account some SOL
  setup_composer.add_instruction(
    Solace::Composers::SystemProgramTransferComposer.new(
      from: setup_payer,
      to: keypair,
      lamports: 10_000_000_000
    )
  )

  # Create the associated token account if it doesn't exist
  unless ata_exists
    setup_composer.add_instruction(
      Solace::Composers::AssociatedTokenAccountProgramCreateAccountComposer.new(
        mint: mint,
        owner: keypair,
        funder: setup_payer,
        ata_address: ata_address
      )
    )
  end

  # Mint tokens to the accounts
  setup_composer.add_instruction(
    Solace::Composers::SplTokenProgramMintToComposer.new(
      amount: TOKENS_AIRDROP,
      mint: mint,
      destination: ata_address,
      mint_authority: mint_authority
    )
  )
end

# Set the fee payer for the setup composer
setup_composer.set_fee_payer(setup_payer)

# The transaction
tx = nil

# Creating a mint if it doesn't exist yet with funded accounts for
if connection.get_account_info(mint.address).nil?
  puts "\n============= Creating Mint ==============="
  puts "⤷ Mint Address: #{mint.address}"
  puts "⤷ Mint Authority: #{mint_authority.address}"

  create_mint_composer = spl_token_program.compose_create_mint(
    funder: setup_payer,
    decimals: 6,
    mint_account: mint,
    mint_authority: mint_authority
  )

  # Merge the create mint transaction into the main composer
  setup_composer.merge(create_mint_composer, placement: :prepend)

  # Sign with all required signers
  tx = setup_composer.compose_transaction
  tx.sign(setup_payer, mint_authority, mint)
else
  puts "\n============= Mint Already Exists ==============="
  puts "⤷ Mint Address: #{mint.address}"
  puts "⤷ Mint Authority: #{mint_authority.address}"

  # Just compose the transaction
  tx = setup_composer.compose_transaction
  tx.sign(setup_payer, mint_authority)
end

# Explorer URL
explorer_url = "https://explorer.solana.com/tx/#{tx.signature}?cluster=custom&customUrl=#{rpc_url}".freeze

# Send the transaction
begin
  connection.send_transaction(tx.serialize)
rescue StandardError => e
  puts "Error sending transaction: #{e.message}"
  puts "Transaction Details: #{e.rpc_data}"
  raise e
end

puts "\n============= Sending Setup Transaction ==============="
puts "⤷ Transaction Signature: #{tx.signature}"
with_spinner("Waiting for confirmation #{explorer_url}") do
  connection.wait_for_confirmed_signature('finalized') { tx.signature }
end

puts "\nBootstrapping Complete!"

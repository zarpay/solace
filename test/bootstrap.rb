# frozen_string_literal: true

# test/bootstrap.rb

# Bootstraps the test environment with a Solana test validator and some pre-funded accounts.

require 'minitest/mock'
require 'minitest/autorun'
require 'minitest/hooks/default'

require 'solace'

require_relative 'support/fixtures'
require_relative 'support/factory_bot'
require_relative 'support/solana_test_validator'

# Make sure keypairs are loaded
bob = Fixtures.load_keypair('bob')
anna = Fixtures.load_keypair('anna')
payer = Fixtures.load_keypair('payer')
mint = Fixtures.load_keypair('mint')
mint_authority = Fixtures.load_keypair('mint-authority')
fee_collector = Fixtures.load_keypair('fee-collector')

# Make sure connection is loaded
connection = Solace::Connection.new(commitment: 'finalized')
spl_token_program = Solace::Programs::SplToken.new(connection: connection)
ata_program = Solace::Programs::AssociatedTokenAccount.new(connection: connection)

# Amounts to airdrop
TOKENS_AIRDROP = 10_000_000
LAMPORTS_AIRDROP = 10_000_000_000

puts "Bootstrapping...\n\n"
setup_payer = Solace::Keypair.generate
result = connection.request_airdrop(setup_payer.address, LAMPORTS_AIRDROP)
connection.wait_for_confirmed_signature('finalized') { result['result'] }

# Create mint
if connection.get_account_info(mint.address).nil?
  puts '============= Creating Mint ==============='
  puts "⤷ Mint Address: #{mint.address}"
  puts "⤷ Mint Authority: #{mint_authority.address}"

  response = spl_token_program.create_mint(
    payer: setup_payer,
    decimals: 6,
    freeze_authority: nil,
    mint_keypair: mint,
    mint_authority: mint_authority
  )
  connection.wait_for_confirmed_signature('finalized') { response['result'] }
end

[
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
].each do |account|
  # Extract name and keypair from account hash
  name, keypair = account.values_at(:name, :keypair)

  puts "\n\n========== Bootstrapping #{name} =========="

  puts "⤷ Airdropping #{LAMPORTS_AIRDROP / 1_000_000_000} SOL..."
  result = connection.request_airdrop(keypair.address, LAMPORTS_AIRDROP)

  puts "⤷ Signature: #{result['result']}"
  connection.wait_for_confirmed_signature('finalized') { result['result'] }

  puts "⤷ Airdropping #{TOKENS_AIRDROP / 1_000_000} tokens..."
  bob_ata = ata_program.get_or_create_address(
    payer: setup_payer,
    owner: keypair,
    mint: mint,
    commitment: 'finalized'
  )

  result = spl_token_program.mint_to(
    payer: setup_payer,
    mint: mint,
    destination: bob_ata,
    amount: TOKENS_AIRDROP,
    mint_authority: mint_authority
  )

  puts "⤷ Signature: #{result['result']}"
  connection.wait_for_confirmed_signature('finalized') { result['result'] }
end

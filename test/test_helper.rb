# frozen_string_literal: true

# test/test_helper.rb

# Loads the environment and runs all Minitest tests in the test directory

require 'minitest/mock'
require 'minitest/autorun'
require 'minitest/hooks/default'

if ENV['USE_GEM']
  puts 'Requiring installed gem'
  require 'solace'
else
  puts 'Autoloading local files'
  project_root = File.expand_path('..', __dir__)
  # Autoload all Ruby files in utils and other directories as needed
  Dir[File.join(project_root, 'lib', '**', '*.rb')].sort.each { |file| require file }
end

require_relative './support/fixtures'
require_relative './support/factory_bot'
require_relative './support/solana_test_validator'

# Make sure keypairs are loaded
bob = Fixtures.load_keypair('bob')
alice = Fixtures.load_keypair('anna')
payer = Fixtures.load_keypair('payer')
mint = Fixtures.load_keypair('mint')
fee_collector = Fixtures.load_keypair('fee-collector')
mint_authority = Fixtures.load_keypair('mint-authority')

# Make sure connection is loaded
connection = Solace::Connection.new

ata_program = Solace::Programs::AssociatedTokenAccount.new(connection:)

connection.wait_for_confirmed_signature do
  puts 'Funding Bob...'
  connection.request_airdrop(bob.address, 10_000_000_000)['result']
end

balance = connection.get_balance(bob.address)
puts "Bob's balance: #{balance} Lamports"

connection.wait_for_confirmed_signature do
  puts 'Funding Anna...'
  connection.request_airdrop(alice.address, 10_000_000_000)['result']
end

balance = connection.get_balance(alice.address)
puts "Alice's balance: #{balance} Lamports"

connection.wait_for_confirmed_signature do
  puts 'Funding Payer...'
  connection.request_airdrop(payer.address, 100_000_000_000)['result']
end

balance = connection.get_balance(payer.address)
puts "Payer's balance: #{balance} Lamports"

# Create ata for all accounts
payer_ata, _ = ata_program.get_or_create_address(owner: payer, mint:, payer:)
puts "Payer's ATA: #{payer_ata}"

bob_ata, _ = ata_program.get_or_create_address(owner: bob, mint:, payer:)
puts "Bob's ATA: #{bob_ata}"

alice_ata, _ = ata_program.get_or_create_address(owner: alice, mint:, payer:)
puts "Alice's ATA: #{alice_ata}"

fee_collector_ata, _ = ata_program.get_or_create_address(owner: fee_collector, mint:, payer:)
puts "Fee Collector's ATA: #{fee_collector_ata}"

# If the mint account doesn't exist, create it
if connection.get_account_info(mint.address).nil?
  puts "Creating Mint..."
  program = Solace::Programs::SplToken.new(connection:)

  connection.wait_for_confirmed_signature do
    program.create_mint(
      payer:,
      decimals: 6,
      freeze_authority: nil,
      mint_keypair: mint,
      mint_authority:,
    )['result']
  end
end

puts "Mint address: #{mint.address}"



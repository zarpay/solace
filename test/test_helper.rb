# frozen_string_literal: true

# test/test_helper.rb

# Loads the environment and runs all Minitest tests in the test directory

project_root = File.expand_path('..', __dir__)

# Autoload all Ruby files in utils and other directories as needed
Dir[File.join(project_root, 'lib', '**', '*.rb')].sort.each { |file| require file }

require 'minitest/mock'
require 'minitest/autorun'
require 'minitest/hooks/default'

require 'solace'

require_relative './support/fixtures'
require_relative './support/factory_bot'
require_relative './support/solana_test_validator'

# Make sure keypairs are loaded
bob = Fixtures.load_keypair('bob')
alice = Fixtures.load_keypair('anna')
payer = Fixtures.load_keypair('payer')
mint = Fixtures.load_keypair('mint')
mint_authority = Fixtures.load_keypair('mint-authority')

# Make sure connection is loaded
connection = Solace::Connection.new

# Request airdrops for both keypairs
connection.wait_for_confirmed_signature do
  puts 'Funding Bob...'
  connection.request_airdrop(bob.address, 10_000_000_000)['result']
end

balance = connection.get_balance(bob.address)
puts "Bob's balance: #{balance} Lamports"

# Request airdrops for both keypairs
connection.wait_for_confirmed_signature do
  puts 'Funding Anna...'
  connection.request_airdrop(alice.address, 10_000_000_000)['result']
end

balance = connection.get_balance(alice.address)
puts "Alice's balance: #{balance} Lamports"

# Request airdrops for payer
connection.wait_for_confirmed_signature do
  puts 'Funding Payer...'
  connection.request_airdrop(payer.address, 100_000_000_000)['result']
end

balance = connection.get_balance(payer.address)
puts "Payer's balance: #{balance} Lamports"

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



# frozen_string_literal: true

# test/test_helper.rb

# Loads the environment and runs all Minitest tests in the test directory

project_root = File.expand_path('..', __dir__)

# Autoload all Ruby files in utils and other directories as needed
Dir[File.join(project_root, 'lib', '**', '*.rb')].sort.each { |file| require file }

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

# Make sure connection is loaded
conn = Solace::Connection.new

# Request airdrops for both keypairs
conn.wait_for_confirmed_signature do
  puts 'Funding Bob...'
  conn.request_airdrop(bob.address, 10_000_000_000)['result']
end

# Request airdrops for both keypairs
conn.wait_for_confirmed_signature do
  puts 'Funding Anna...'
  conn.request_airdrop(alice.address, 10_000_000_000)['result']
end

# Request airdrops for payer
conn.wait_for_confirmed_signature do
  puts 'Funding Payer...'
  conn.request_airdrop(payer.address, 100_000_000_000)['result']
end

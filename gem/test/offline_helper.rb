# frozen_string_literal: true

# Loads Solace and Minitest without a Solana node, for tests that talk to a
# fake server on a local socket. test_helper adds the validator on top.
require 'bundler'
require 'minitest/mock'
require 'minitest/autorun'
require 'minitest/hooks/default'

if ENV['USE_GEM']
  puts 'Requiring installed gem'
  require 'solace'
else
  puts 'Requiring local files'
  solace = File.expand_path('../lib/solace.rb', __dir__)
  require solace
end

require_relative 'support/fake_rpc_server'

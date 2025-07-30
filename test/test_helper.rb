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
  puts 'Requiring local files'
  solace = File.expand_path('../lib/solace.rb', __dir__)
  require solace
end

require_relative 'support/fixtures'
require_relative 'support/factory_bot'
require_relative 'support/solana_test_validator'

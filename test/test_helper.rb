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

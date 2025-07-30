# frozen_string_literal: true

require 'irb'

# Autoload all Ruby files in utils and other directories as needed
Dir[File.join(__dir__, 'lib', '**', '*.rb')].each { |file| require file }

require 'minitest/autorun'
require 'minitest/hooks/default'

require_relative 'test/support/fixtures'
require_relative 'test/support/factory_bot'
require_relative 'test/support/solana_test_validator'

# Start IRB
IRB.start

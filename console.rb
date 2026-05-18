# frozen_string_literal: true

require 'irb'

$LOAD_PATH.unshift(File.expand_path('lib', __dir__))
require 'solace'

require 'minitest/autorun'
require 'minitest/hooks/default'

require_relative 'test/support/fixtures'
require_relative 'test/support/factory_bot'
require_relative 'test/support/solana_test_validator'

# Start IRB
IRB.start

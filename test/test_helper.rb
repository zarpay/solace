# test/test_helper.rb
 
# Loads the environment and runs all Minitest tests in the test directory

project_root = File.expand_path('..', __dir__)

# Autoload all Ruby files in utils and other directories as needed
Dir[File.join(project_root, 'lib', '**', '*.rb')].sort.each { |file| require file }

require 'minitest/autorun'
require 'solana'

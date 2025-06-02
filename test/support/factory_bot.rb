require 'factory_bot'

class Minitest::Test
  include FactoryBot::Syntax::Methods
end

FactoryBot.definition_file_paths = [File.expand_path('../factories', __dir__)]
FactoryBot.find_definitions

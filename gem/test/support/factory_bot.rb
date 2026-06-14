# frozen_string_literal: true

require 'factory_bot'

module Minitest
  class Test
    include FactoryBot::Syntax::Methods
  end
end

FactoryBot.definition_file_paths = [File.expand_path('../factories', __dir__)]
FactoryBot.find_definitions

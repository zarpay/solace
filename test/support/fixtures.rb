# frozen_string_literal: true

module Fixtures
  # Load a keypair fixture
  #
  # @param fixture_name [String] The name of the fixture file
  # @return [Solace::Keypair] The keypair object
  def self.load_keypair(fixture_name)
    Solace::Keypair.from_secret_key load(fixture_name).pack('C*')
  end

  # Loads a fixture file
  #
  # @param fixture_name [String] The name of the fixture file
  # @return [Array] The contents of the fixture file
  def self.load(fixture_name)
    JSON.load_file(File.expand_path("#{fixture_name}.json", path))
  end

  # Returns the path to the fixture directory
  def self.path
    File.expand_path('../fixtures', __dir__)
  end
end

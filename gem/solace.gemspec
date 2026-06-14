# frozen_string_literal: true

require_relative 'lib/solace/version'

Gem::Specification.new do |spec|
  spec.name          = 'solace'
  spec.version       = Solace::VERSION
  spec.authors       = ['Sebastian Scholl']
  spec.email         = ['sebscholl@gmail.com']
  spec.summary       = 'Solana ruby library'
  spec.homepage      = 'https://github.com/zarpay/solace'
  spec.description   = 'A Ruby library for working with Solana blockchain. Provides both low-level instruction builders and high-level program clients for interacting with Solana programs.'
  spec.license       = 'MIT'

  spec.required_ruby_version = '>= 3.0'

  spec.metadata['allowed_push_host']     = 'https://rubygems.org'
  spec.metadata['source_code_uri']       = 'https://github.com/zarpay/solace'
  spec.metadata['changelog_uri']         = 'https://github.com/zarpay/solace/blob/main/CHANGELOG'
  spec.metadata['documentation_uri']     = 'https://zarpay.github.io/solace'
  spec.metadata['rubygems_mfa_required'] = 'true'

  # Packaged files are the library only (including the prebuilt native binaries under
  # lib/solace/utils/); README/LICENSE/CHANGELOG live at the repo root, one level above gem/.
  spec.files         = Dir.glob('lib/**/*').reject { |path| File.directory?(path) }
  spec.require_paths = ['lib']

  # Native binaries are prebuilt and shipped under lib/ — this is a pure-Ruby platform gem.
  spec.platform = Gem::Platform::RUBY

  # Runtime dependencies
  spec.add_dependency 'base58', '~> 0.2'
  spec.add_dependency 'ffi', '~> 1.15'
  spec.add_dependency 'rbnacl', '~> 7.0'

  # Development dependencies
  spec.add_development_dependency 'factory_bot'
  spec.add_development_dependency 'minitest', '~> 5.0'
  spec.add_development_dependency 'minitest-hooks'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'redcarpet'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'rubocop-yard'
  spec.add_development_dependency 'tty-spinner'
  spec.add_development_dependency 'yard'
  spec.add_development_dependency 'yardstick'

  # Post-install message
  spec.post_install_message = <<~MSG

    Thank you for installing Solace!

    This gem includes native binaries for curve25519 operations.
    If you encounter any issues with native library loading,
    please check that your platform is supported or file an issue at:
    https://github.com/zarpay/solace/issues

  MSG
end

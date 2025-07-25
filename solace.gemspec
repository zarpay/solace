# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = 'solace'
  spec.version       = '0.0.2'
  spec.authors       = ['Sebastian Scholl']
  spec.email         = ['sebastian@scholl.io']
  spec.summary       = 'Solana ruby library'
  spec.homepage      = 'https://github.com/sebscholl/solace'
  spec.description   = 'A Ruby library for working with Solana blockchain. Provides both low-level instruction builders and high-level program clients for interacting with Solana programs.'
  spec.license       = 'MIT'

  spec.files         = Dir[
    'lib/**/*',
    'README.md',
    'LICENSE',
    'CHANGELOG'
  ]
  spec.require_paths = ['lib']

  # Runtime dependencies
  spec.add_dependency 'base58', '~> 0.2'
  spec.add_dependency 'ffi', '~> 1.15'
  spec.add_dependency 'rbnacl', '~> 7.0'

  # Development dependencies
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'minitest', '~> 5.0'

  # Required Ruby version
  spec.required_ruby_version = '>= 3.0'

  # Platform-specific gems for native binaries
  spec.platform = Gem::Platform::RUBY
    
  # Post-install message
  spec.post_install_message = <<~MSG

    Thank you for installing Solace!
    
    This gem includes native binaries for curve25519 operations.
    If you encounter any issues with native library loading,
    please check that your platform is supported or file an issue at:
    https://github.com/sebscholl/solace/issues

  MSG
end

# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = 'solace'
  spec.version       = '0.0.1'
  spec.authors       = ['Sebastian Scholl']
  spec.email         = ['sebastian@scholl.io']
  spec.summary       = 'Solana ruby library'
  spec.description   = 'A Ruby library for working with Solana.'
  spec.homepage      = 'https://github.com/sebscholl/solace'
  spec.license       = 'MIT'

  spec.files         = Dir['lib/**/*', 'ext/**/*', 'Cargo.toml', 'Cargo.lock']
  spec.require_paths = ['lib']

  spec.add_dependency 'base58', '~> 0.2'
  spec.add_dependency 'ffi', '~> 1.15'
  spec.add_dependency 'rbnacl', '~> 7.0'

  spec.required_ruby_version = '>= 3.0'
end

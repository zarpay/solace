Gem::Specification.new do |spec|
  spec.name          = "solana-on-ruby"
  spec.version       = "0.0.1"
  spec.authors       = ["Sebastian Scholl"]
  spec.email         = ["sebastian@scholl.io"]
  spec.summary       = "Solana ruby library"
  spec.description   = "A Ruby library for working with Solana."
  spec.homepage      = "https://github.com/sebscholl/solana-on-ruby"
  spec.license       = "MIT"

  spec.files         = Dir["lib/**/*.rb"]
  spec.require_paths = ["lib"]

  spec.add_dependency "base58", "~> 0.2"
  spec.add_dependency "rbnacl", "~> 7.0"

  spec.required_ruby_version = ">= 3.0"
end
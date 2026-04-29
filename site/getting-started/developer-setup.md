# Developer Setup

This guide walks through setting up the Solace repo for local development and running the test suite. If you're looking to use Solace as a dependency in your own project, see the [Quick Start](/getting-started/).

## Prerequisites

- Ruby >= 3.0
- Bundler
- Rust toolchain (only if you need to recompile the curve25519 native library)

## Clone and install

```bash
git clone https://github.com/zarpay/solace.git
cd solace/gem
bundle install
```

## System dependencies

### libsodium

Solace uses `rbnacl` for Ed25519 cryptography, which requires libsodium.

**macOS:**

```bash
brew install libsodium
```

**Ubuntu / Debian:**

```bash
sudo apt-get install -y libsodium-dev
```

### Solana CLI

The test suite runs a local `solana-test-validator`. Install the Solana CLI:

```bash
sh -c "$(curl -sSfL https://release.anza.xyz/stable/install)"
```

Restart your shell (or export the path it prints) and verify:

```bash
solana-test-validator --version
```

## Bootstrap the test environment

The bootstrap task starts a local validator, generates fixture keypairs, funds them with SOL, creates a token mint, and sets up associated token accounts:

```bash
cd gem
bundle exec rake bootstrap
```

This only needs to run once. The fixture keypairs live in `gem/test/fixtures/` and are committed to the repo, so subsequent runs reuse the same accounts against a fresh validator ledger.

## Run the tests

```bash
cd gem
bundle exec rake test
```

The test suite automatically starts and stops `solana-test-validator`. Tests that hit the local validator (composers, programs, on-chain instruction tests) run against the bootstrapped accounts. Unit tests (serializers, codecs, keypairs, etc.) run without network access.

## Project layout

```
solace/
├── gem/                  # Ruby gem source
│   ├── lib/solace/       # Library code
│   ├── test/             # Minitest suite
│   │   ├── fixtures/     # Keypair JSON fixtures
│   │   ├── factories/    # FactoryBot definitions
│   │   ├── support/      # Test helpers (validator, fixtures)
│   │   └── solace/       # Tests mirror lib/ structure
│   ├── ext/              # Rust FFI source (curve25519)
│   ├── Gemfile
│   ├── Rakefile
│   └── solace.gemspec
├── site/                 # VitePress documentation
└── .github/workflows/    # CI
```

## Useful rake tasks

| Command | What it does |
| --- | --- |
| `bundle exec rake test` | Run the full test suite |
| `bundle exec rake bootstrap` | Bootstrap fixture accounts on a local validator |
| `bundle exec rake build` | Build the `.gem` file into `builds/` |
| `bundle exec rake compile` | Cross-compile the Rust curve25519 library for all platforms |

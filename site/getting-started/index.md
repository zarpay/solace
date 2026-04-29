# Quick Start

## Installation

Add Solace to your Gemfile:

```ruby
gem 'solace'
```

Then run:

```bash
bundle install
```

Or install it directly:

```bash
gem install solace
```

### System dependencies

Solace depends on [libsodium](https://doc.libsodium.org/) for Ed25519 cryptography via the `rbnacl` gem.

**macOS:**

```bash
brew install libsodium
```

**Ubuntu / Debian:**

```bash
sudo apt-get install libsodium-dev
```

## Your first transaction

Connect to devnet, fund a keypair via airdrop, and transfer SOL:

```ruby
require 'solace'

# Connect to devnet
connection = Solace::Connection.new('https://api.devnet.solana.com')

# Generate keypairs
payer = Solace::Keypair.generate
recipient = Solace::Keypair.generate

# Fund the payer (devnet only)
response = connection.request_airdrop(payer.address, 1_000_000_000)
connection.wait_for_confirmed_signature('finalized') { response['result'] }

# Build and send a transfer
composer = Solace::TransactionComposer.new(connection: connection)

composer.add_instruction(
  Solace::Composers::SystemProgramTransferComposer.new(
    from: payer.address,
    to: recipient.address,
    lamports: 100_000_000  # 0.1 SOL
  )
)

composer.set_fee_payer(payer.address)

tx = composer.compose_transaction
tx.sign(payer)

response = connection.send_transaction(tx.serialize)
puts "Signature: #{response['result']}"
```

## Next steps

- Read the [Architecture](/getting-started/architecture) overview to understand the SDK layers
- Dive into [Keypairs](/core/keypairs) and [Connections](/core/connections) for the core primitives
- Learn about [Composers](/composers/overview) for the recommended way to build transactions

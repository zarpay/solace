# Solace

A Ruby library for interacting with the Solana blockchain.

## Overview

Solace provides a Ruby interface to the Solana blockchain, allowing developers to create, sign, and send transactions, manage keypairs, and interact with Solana programs. This library aims to make Solana blockchain development accessible to the Ruby ecosystem.

## Features

- **Keypair Management**: Generate, import, and manage Ed25519 keypairs for Solana
- **RPC Client**: Connect to Solana nodes and interact with the blockchain
- **Transaction Construction**: Build, sign, and send transactions to the Solana network
- **System Program**: Create accounts and transfer SOL between accounts
- **Token Program (Partial)**: Basic SPL Token functionality
- **Binary Serialization**: Serialize and deserialize Solana data structures

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'solace'
```

And then execute:

```
$ bundle install
```

Or install it yourself as:

```
$ gem install solace
```

## Requirements

- Ruby 3.0 or higher
- FFI 1.15 or higher
- Base58 0.2 or higher
- RbNaCl 7.0 or higher

## Usage Examples

### Creating a Keypair

```ruby
require 'solace'

# Generate a new random keypair
keypair = Solace::Keypair.generate

# Get the public key as a Base58 string
address = keypair.address
puts "Address: #{address}"

# Create a keypair from an existing seed
seed = # 32-byte seed
keypair_from_seed = Solace::Keypair.from_seed(seed)

# Create a keypair from an existing secret key
secret_key = # 64-byte secret key
keypair_from_secret = Solace::Keypair.from_secret_key(secret_key)
```

### Connecting to a Solana Node

```ruby
# Connect to a local node
connection = Solace::Connection.new("http://localhost:8899")

# Connect to a public node
devnet = Solace::Connection.new("https://api.devnet.solana.com")
mainnet = Solace::Connection.new("https://api.mainnet-beta.solana.com")
```

### Transferring SOL

```ruby
require 'solace'

# Setup connection and keypairs
connection = Solace::Connection.new("http://localhost:8899")
sender = Solace::Keypair.generate
recipient = Solace::Keypair.generate

# Request airdrop for testing (only works on test networks)
connection.request_airdrop(sender.address, 1_000_000_000) # 1 SOL

# Create a transfer instruction
transfer_instruction = Solace::Instructions::TransferInstruction.new(
  from_pubkey: sender.public_key,
  to_pubkey: recipient.public_key,
  lamports: 500_000_000 # 0.5 SOL
)

# Create a new message with the instruction
message = Solace::Message.new(
  instructions: [transfer_instruction],
  payer: sender.public_key
)

# Set the recent blockhash
message.recent_blockhash = connection.get_latest_blockhash

# Create and sign the transaction
transaction = Solace::Transaction.new(message: message)
transaction.sign(sender)

# Send the transaction
result = connection.send_transaction(transaction.to_base64)
puts "Transaction signature: #{result["result"]}"
```

### Creating an Account

```ruby
# Create an account instruction
create_account_instruction = Solace::Instructions::SystemProgram::CreateAccountInstruction.new(
  from_pubkey: payer.public_key,
  new_account_pubkey: new_account.public_key,
  lamports: connection.get_minimum_lamports_for_rent_exemption(data_size),
  space: data_size,
  program_id: program_id
)

# Then add to a transaction and sign as in the transfer example
```

## Current Status and Roadmap

Solace is under active development. The current implementation includes:

- ✅ Keypair/PublicKey management
- ✅ RPC Client (Connection)
- ✅ Transaction Construction/Signing
- ✅ System Program (transfer, create account)
- 🚧 Token Program (partial implementation)
- 🚧 Account Data Parsing (partial implementation)
- 🚧 Utility Functions (partial implementation)

See the [FEATURES.md](FEATURES.md) file for a complete feature coverage list and roadmap.

## Contributing

Bug reports and pull requests are welcome on GitHub. This project is intended to be a safe, welcoming space for collaboration.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

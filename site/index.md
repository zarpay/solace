---
layout: home
hero:
  name: Solace
  text: A Ruby SDK for the Solana blockchain
  tagline: Solace provides both low-level building blocks and high-level abstractions for composing, signing, and sending Solana transactions — all in idiomatic Ruby.
  actions:
    - theme: brand
      text: Start with Quick Start
      link: /getting-started/
    - theme: alt
      text: Explore Core Concepts
      link: /core/keypairs
---

## What a transaction looks like

A Solace transaction is built from keypairs, instructions, and a connection to a Solana RPC node.

```ruby
require 'solace'

connection = Solace::Connection.new('https://api.devnet.solana.com')

payer = Solace::Keypair.generate
recipient = Solace::Keypair.generate

composer = Solace::TransactionComposer.new(connection: connection)

composer.add_instruction(
  Solace::Composers::SystemProgramTransferComposer.new(
    from: payer.address,
    to: recipient.address,
    lamports: 100_000_000
  )
)

composer.set_fee_payer(payer.address)

tx = composer.compose_transaction
tx.sign(payer)

response = connection.send_transaction(tx.serialize)
puts "Transaction: #{response['result']}"
```

## What's happening here

| Piece | What it does | Docs |
| --- | --- | --- |
| `Solace::Connection` | RPC client that talks to a Solana node — sends transactions, fetches blockhashes, queries balances. | [Connections](/core/connections) |
| `Solace::Keypair` | Ed25519 keypair for signing. Wraps `rbnacl` and gives you `.address` (Base58 public key). | [Keypairs](/core/keypairs) |
| `Solace::TransactionComposer` | Collects instruction composers, deduplicates accounts, calculates the message header, and produces a ready-to-sign transaction. | [Composers](/composers/overview) |
| `SystemProgramTransferComposer` | A built-in instruction composer for SOL transfers. Declares its accounts and builds the binary instruction data. | [Composers](/composers/overview) |
| `tx.sign(payer)` | Signs the serialized message bytes with one or more keypairs. | [Transactions](/core/transactions) |
| `connection.send_transaction(...)` | Submits the Base64-encoded transaction to the RPC node. | [Connections](/core/connections) |

## How to read this

The handbook moves outward from the basics:

- **Getting Started** — installation, a minimum transaction, and the architecture overview
- **Core** — keypairs, connections, transactions, messages, instructions
- **Composers** — the high-level transaction builder and how to write custom instruction composers
- **Programs** — SPL Token and Associated Token Account program clients
- **Utilities** — codecs, PDA derivation, curve25519 operations
- **Reference** — constants, error classes, serializers

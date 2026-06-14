---
title: Quick Start
---

# Quick Start

This walks through the whole arc: install the gem, connect to a cluster, generate a
keypair, and send a SOL transfer two ways — once with the low-level primitives, and once
with the high-level composer layer.

## Install

Add the gem to your `Gemfile`:

```ruby
gem 'solace'
```

```sh
bundle install
```

```ruby
require 'solace'
```

Native binaries for the Curve25519 operations ship with the gem (Linux, macOS, Windows;
x86_64 and ARM64), so there's nothing to compile.

## Connect and generate a keypair

```ruby
# Defaults to http://localhost:8899. Pass a URL for devnet / mainnet.
connection = Solace::Connection.new('https://api.devnet.solana.com')

payer = Solace::Keypair.generate
puts payer.address # base58 public key

# On devnet you can fund it:
connection.request_airdrop(payer.address, 1_000_000_000) # 1 SOL
```

`Keypair.generate` makes a fresh Ed25519 key. To load an existing one, use
`Keypair.from_secret_key(bytes)` or `Keypair.from_seed(seed)` — see
[Keypairs & Public Keys](/concepts/keypairs-and-public-keys).

## Send a transfer — the low-level way

At the lowest level you assemble the [message](/concepts/transactions-and-messages)
yourself: order the accounts, build the instruction against those indices, set the
header, and sign.

```ruby
recipient = Solace::Keypair.generate

blockhash, = connection.get_latest_blockhash

message = Solace::Message.new(
  header:           [1, 0, 1], # [required_signatures, readonly_signed, readonly_unsigned]
  accounts:         [
    payer.address,
    recipient.address,
    Solace::Constants::SYSTEM_PROGRAM_ID
  ],
  instructions:     [
    Solace::Instructions::SystemProgram::TransferInstruction.build(
      lamports:      1_000_000,
      from_index:    0,
      to_index:      1,
      program_index: 2
    )
  ],
  recent_blockhash: blockhash
)

tx = Solace::Transaction.new(message:)
tx.sign(payer)

result = connection.send_transaction(tx.serialize)
connection.wait_for_confirmed_signature { result['result'] }
```

## Send a transfer — the composer way

The [composer layer](/building/composers) does the account bookkeeping for you. You
declare instructions; `TransactionComposer` builds the account list, computes the header,
and fetches the blockhash.

```ruby
recipient = Solace::Keypair.generate

tx = Solace::TransactionComposer.new(connection:)
                                .add_instruction(
                                  Solace::Composers::SystemProgramTransferComposer.new(
                                    from:     payer.address,
                                    to:       recipient.address,
                                    lamports: 1_000_000
                                  )
                                )
                                .set_fee_payer(payer.address)
                                .compose_transaction

tx.sign(payer)
result = connection.send_transaction(tx.serialize)
connection.wait_for_confirmed_signature { result['result'] }
```

For token operations there's a third, even higher level — the
[program clients](/building/program-clients), e.g. `Solace::Programs::SplToken`, which
sign and submit in a single call.

## Where to next

- [Conventions](/conventions) — the cross-cutting rules: the four layers, how pubkey
  arguments accept strings/keys/keypairs, and the `sign:`/`execute:` controls.
- [Core Concepts](/concepts/keypairs-and-public-keys) — the primitives behind everything:
  keypairs, the connection, transactions, messages, instructions, and account ordering.
- [Building Transactions](/building/instruction-builders) — the layered workflow, and the
  blueprint for adding your own program support.
- [Programs](/programs/system-program) — the bundled program clients, documented at the
  program-client, composer, and instruction level.

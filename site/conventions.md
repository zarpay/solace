---
title: Conventions
---

# Conventions

Solace is consistent across its surface, and the docs assume a small set of cross-cutting
rules. Read this page once; the rest of the docs lean on it.

## The four layers

Solace is organized as four layers. Each operation is reachable at more than one of them,
from highest (most convenient) to lowest (most control):

| Layer | What it is | Reach for it when |
| --- | --- | --- |
| **Program client** | A send-and-sign method on a `Solace::Programs::*` client (e.g. `SplToken#create_mint`). Derives accounts, builds the transaction, signs, and submits. | The common case — one call that does everything. |
| **Composer** | A `Solace::Composers::Base` subclass (e.g. `SystemProgramTransferComposer`) that contributes one instruction to a transaction and manages its own accounts. | You're batching several instructions into one transaction, or want control over the fee payer and signing. |
| **Instruction builder** | A stateless `.build` method (e.g. `Instructions::SystemProgram::TransferInstruction`) that encodes one raw instruction from account **indices**. | You need byte-level control and are assembling the message yourself. |
| **Core primitive** | `Keypair`, `Connection`, `Transaction`, `Message`, `Instruction`, `AccountContext`. | The foundation the other three are built on. |

The [Programs](/programs/system-program) pages document each operation at the top three
levels; the [Core Concepts](/concepts/keypairs-and-public-keys) and
[Building Transactions](/building/instruction-builders) sections cover the primitives and
the assembly layers in depth.

## Pubkey arguments accept strings, public keys, or keypairs

Any argument whose type is written **`#to_s`** accepts a base58 `String`, a
`Solace::PublicKey`, or a `Solace::Keypair` — they are all normalized with `.to_s`, which
returns the base58 address. So these are equivalent:

```ruby
composer = Solace::Composers::SystemProgramTransferComposer.new(
  from:     payer,            # a Keypair
  to:       recipient.address, # a base58 String
  lamports: 1_000_000
)
```

An argument typed **`Keypair`** needs an actual `Solace::Keypair`, because the transaction
requires its signature.

## Indices vs. addresses

The two lower layers differ in how they refer to accounts:

- **Composers** and **program clients** take **addresses** (`#to_s`). They register the
  accounts with an [`AccountContext`](/concepts/account-context), which assigns each a
  position.
- **Instruction builders** take **indices** — integers into the message's compiled account
  list. You get them from `context.index_of(address)`. This is why builders are the
  "advanced" layer: you own the account ordering.

## Signing and sending

The primitive flow is always: build a `Transaction`, `sign` it with one or more keypairs,
then `serialize` and hand it to `connection.send_transaction`:

```ruby
tx.sign(payer, other_signer)        # variadic; appends each signature
sig = connection.send_transaction(tx.serialize)
connection.wait_for_confirmed_signature { sig['result'] }
```

The **program clients** wrap this. Every send-and-sign method takes the same two control
keywords in addition to its domain arguments:

| Parameter | Type | Default | Description |
| --- | --- | --- | --- |
| `sign` | Boolean | `true` | Sign the transaction with the operation's required keypairs. |
| `execute` | Boolean | `true` | Submit the signed transaction to the cluster. Set `false` to build/sign without sending. |

They return a `Solace::Transaction` — already submitted when `execute: true`. Pass
`execute: false` to inspect or send it yourself, or `sign: false` for an unsigned
transaction.

## Reusable setup

Examples throughout the docs assume a connection is in scope:

```ruby
require 'solace'

connection = Solace::Connection.new # http://localhost:8899
payer      = Solace::Keypair.generate # a funded keypair
```

---
title: Program Clients
---

# Program Clients

Program clients are the highest layer: send-and-sign objects that wrap an entire operation.
A method like `SplToken#create_mint` derives the accounts it needs, builds the transaction
via the [composer layer](/building/transaction-composer), signs it, and submits it — all in
one call. They live under `lib/solace/programs/` and subclass `Solace::Programs::Base`.

## Construction

```ruby
spl       = Solace::Programs::SplToken.new(connection:)
token2022 = Solace::Programs::Token2022.new(connection:)
ata       = Solace::Programs::AssociatedTokenAccount.new(connection:)
```

`Solace::Programs::Base.new(connection:, program_id:)` is the parent; the concrete clients
default `program_id` to the right program, so you only pass `connection:`. The
[Programs](/programs/system-program) section documents each client's methods.

| Accessor | Description |
| --- | --- |
| `connection` | The bound `Connection`. |
| `program_id` | The program this client targets. |

## The send-and-sign convention

Every action method takes its domain arguments plus two shared controls:

| Parameter | Type | Default | Description |
| --- | --- | --- | --- |
| `sign` | Boolean | `true` | Sign with the operation's required keypairs. |
| `execute` | Boolean | `true` | Submit to the cluster. `false` builds/signs without sending. |

and returns a `Solace::Transaction`:

```ruby
tx = spl.create_mint(
  payer:          payer,
  funder:         payer,
  decimals:       6,
  mint_authority: payer.address
)

connection.wait_for_confirmed_signature { tx.signature }
```

Pass `execute: false` to inspect or send the transaction yourself; pass `sign: false` for
an unsigned one. See [Conventions](/conventions#signing-and-sending).

## `compose_*` counterparts

Each action has a `compose_*` sibling that returns a
[`TransactionComposer`](/building/transaction-composer) instead of sending — so you can add
more instructions, change the fee payer, or batch operations before composing:

```ruby
composer = spl.compose_create_mint(
  funder:         payer,
  decimals:       6,
  mint_authority: payer.address
)

tx = composer.set_fee_payer(payer.address).compose_transaction
tx.sign(payer, mint_account)
connection.send_transaction(tx.serialize)
```

This is the bridge back down to the composer layer when a one-call method isn't flexible
enough.

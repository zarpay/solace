---
title: The Transaction Composer
---

# The Transaction Composer

`Solace::TransactionComposer` assembles one or more [composers](/building/composers) into a
ready-to-sign [`Transaction`](/concepts/transactions-and-messages). It owns an
[`AccountContext`](/concepts/account-context): each composer registers its accounts, then
the transaction composer compiles the ordering, fetches a recent blockhash from the
connection, resolves every instruction's indices, and produces the message.

## Basic use

```ruby
tx = Solace::TransactionComposer.new(connection:)
                                .add_instruction(transfer_composer)
                                .set_fee_payer(payer.address)
                                .compose_transaction

tx.sign(payer)
connection.send_transaction(tx.serialize)
```

`compose_transaction` returns an **unsigned** `Transaction` — you sign it yourself. (The
[program clients](/building/program-clients) wrap this and sign for you.)

## Methods

| Method | Returns | Description |
| --- | --- | --- |
| `new(connection:)` | composer | Create a composer bound to a connection (used to fetch the blockhash). |
| `add_instruction(composer)` | `self` | Append a composer. |
| `prepend_instruction(composer)` | `self` | Insert a composer at the front. |
| `insert_instruction(index, composer)` | `self` | Insert at a position. |
| `set_fee_payer(pubkey)` | `self` | Set the fee payer (`#to_s`); becomes account index 0. |
| `merge(other, placement: :add, index: nil)` | `self` | Merge another `TransactionComposer` (`placement:` `:add`, `:prepend`, or `:insert` with `index:`). |
| `compose_transaction` | `Solace::Transaction` | Compile accounts, fetch blockhash, build the message, return an unsigned transaction. |

| Accessor | Description |
| --- | --- |
| `connection` | The bound `Connection`. |
| `context` | The shared `AccountContext`. |
| `instruction_composers` | The composers added so far. |

## Batching several instructions

Because each composer manages its own accounts, batching is just adding more — shared
accounts are deduplicated automatically:

```ruby
tx = Solace::TransactionComposer.new(connection:)
                                .add_instruction(
                                  Solace::Composers::SystemProgramTransferComposer.new(
                                    from:     payer.address,
                                    to:       alice.address,
                                    lamports: 1_000_000
                                  )
                                )
                                .add_instruction(
                                  Solace::Composers::SystemProgramTransferComposer.new(
                                    from:     payer.address,
                                    to:       bob.address,
                                    lamports: 2_000_000
                                  )
                                )
                                .set_fee_payer(payer.address)
                                .compose_transaction

tx.sign(payer)
connection.send_transaction(tx.serialize)
```

This is the layer to reach for when you want several instructions in one atomic
transaction, or precise control over the fee payer and signing — without dropping all the
way down to hand-built [messages](/concepts/transactions-and-messages).

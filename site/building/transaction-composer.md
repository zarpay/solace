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
| `add_lookup_table(account:, addresses:)` | `self` | Make an [address lookup table](/concepts/address-lookup-tables) available; the composed transaction becomes v0. |
| `merge(other, placement: :add, index: nil)` | `self` | Merge another `TransactionComposer` (`placement:` `:add`, `:prepend`, or `:insert` with `index:`). |
| `compose_transaction` | `Solace::Transaction` | Compile accounts, fetch blockhash, build the message, return an unsigned transaction. |

| Accessor | Description |
| --- | --- |
| `connection` | The bound `Connection`. |
| `context` | The shared `AccountContext`. |
| `instruction_composers` | The composers added so far. |
| `lookup_tables` | The shared `LookupTableContext` holding the registered lookup tables. |

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

## Address lookup tables (v0)

When a transaction touches more accounts than the legacy format can carry, hand the
composer the [address lookup tables](/concepts/address-lookup-tables) it may load through
— each as the table's address plus its full, ordered on-chain address list:

```ruby
tx = Solace::TransactionComposer.new(connection:)
                                .add_instruction(swap_composer)
                                .set_fee_payer(payer.address)
                                .add_lookup_table(
                                  account:   table_address,
                                  addresses: table_addresses
                                )
                                .compose_transaction
```

`compose_transaction` then emits a **v0 message**: every compiled account found in a table
that is allowed to load (a non-signer that is not the fee payer and not a program id of
any instruction) is referenced by table index instead of occupying a static account slot.
Signers, the fee payer, and program ids always stay static — those are runtime rules, not
options. Instruction indices resolve against the combined v0 account space
`[static..., loaded writable..., loaded readonly...]`, matching how the Solana runtime
flattens loaded addresses before execution.

Add as many tables as you like — when an address appears in several, the first table
wins. Registering a table opts the transaction into the v0 format: even if nothing ends
up loadable the message is v0 (with an empty lookup list), mirroring
`@solana/web3.js`. With no tables registered the composer emits a legacy message,
exactly as before.

The bookkeeping lives in `Solace::Utils::LookupTableContext` (exposed as
`composer.lookup_tables`), the lookup-table counterpart to
[`AccountContext`](/concepts/account-context).

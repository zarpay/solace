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
| `add_address_lookup_table(account:, addresses:)` | `self` | Register an [address lookup table](/concepts/address-lookup-tables); the composed transaction becomes v0. |
| `merge(other, placement: :add, index: nil)` | `self` | Merge another `TransactionComposer` (`placement:` `:add`, `:prepend`, or `:insert` with `index:`); its tables fold in too. |
| `compose_transaction` | `Solace::Transaction` | Compile accounts, fetch blockhash, build the message, return an unsigned transaction. |

| Accessor | Description |
| --- | --- |
| `connection` | The bound `Connection`. |
| `context` | The shared `AccountContext`. |
| `instruction_composers` | The composers added so far. |
| `address_lookup_tables` | The registered lookup tables (`Solace::Accounts::AddressLookupTable`). |
| `version` | The transaction version — `nil` (legacy) until a table opts it into `0` (v0). |

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

When a transaction touches more accounts than the legacy format can carry, register the
[address lookup tables](/concepts/address-lookup-tables) it may load through — each as the
table's address plus its full, ordered on-chain address list:

```ruby
tx = Solace::TransactionComposer.new(connection:)
                                .add_instruction(swap_composer)
                                .set_fee_payer(payer.address)
                                .add_address_lookup_table(
                                  account:   table_address,
                                  addresses: table_addresses
                                )
                                .compose_transaction

tx.message.versioned? # => true — registering a table opts into the v0 format
```

`compose_transaction` then emits a **v0 message**: every compiled account found in a table
that is allowed to load (a non-signer that is not the fee payer and not a program id of any
instruction) is referenced by table index instead of occupying a static account slot.
Signers, the fee payer, and program ids always stay static — those are runtime rules, not
options. Register as many tables as you like; when an address appears in several, the first
table wins. `merge` carries a merged composer's tables across too.

Registering a table sets the composer's `version` to `0`, so the transaction stays v0 even
if nothing ends up loadable. With no tables the composer emits a legacy message, exactly as
before.

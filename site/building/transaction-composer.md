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
| `new(connection:, blockhash: nil)` | composer | Create a composer bound to a connection (used to fetch the blockhash unless one is given). |
| `from(transaction, connection:)` | composer | Take a transaction (or its base64) apart into a composer that composes it again; see below. |
| `add_instruction(composer)` | `self` | Append a composer. |
| `prepend_instruction(composer)` | `self` | Insert a composer at the front. |
| `insert_instruction(index, composer)` | `self` | Insert at a position. |
| `set_fee_payer(pubkey)` | `self` | Set the fee payer (`#to_s`); becomes account index 0. |
| `set_compute_budget(units:, micro_lamports:)` | `self` | Set the compute budget; the ComputeBudget instructions are written first when composing, superseding any added as plain instructions. |
| `add_address_lookup_table(account:, addresses:)` | `self` | Register an [address lookup table](/concepts/address-lookup-tables); the composed transaction becomes v0. |
| `merge(other, placement: :add, index: nil)` | `self` | Merge another `TransactionComposer` (`placement:` `:add`, `:prepend`, or `:insert` with `index:`); its tables fold in too. |
| `compose_transaction(blockhash: nil)` | `Solace::Transaction` | Compile accounts, build the message, return an unsigned transaction. Composes against `blockhash:` when given, otherwise fetches the latest from the connection. |

| Accessor | Description |
| --- | --- |
| `connection` | The bound `Connection`. |
| `context` | The shared `AccountContext`. |
| `instruction_composers` | The composers added so far. |
| `address_lookup_tables` | The registered lookup tables (`Solace::Accounts::AddressLookupTable`). |
| `version` | The transaction version — `nil` (legacy) until a table opts it into `0` (v0). |
| `compute_budget` | The compute budget set on the composer (`Solace::Utils::ComputeBudget`): `units`, `micro_lamports`, `set?`. |
| `blockhash` | The blockhash the composer composes against by default — `nil` (fetch the latest) unless given or recovered. |

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

## Setting a compute budget

A compute budget is two ComputeBudget instructions, and you can add them like any other
instruction with the
[`ComputeBudgetProgramSetComputeUnitLimitComposer` and `ComputeBudgetProgramSetComputeUnitPriceComposer`](/building/composers):

```ruby
tx = Solace::TransactionComposer.new(connection:)
                                .add_instruction(Solace::Composers::ComputeBudgetProgramSetComputeUnitLimitComposer.new(units: 200_000))
                                .add_instruction(Solace::Composers::ComputeBudgetProgramSetComputeUnitPriceComposer.new(micro_lamports: 50_000))
                                .add_instruction(transfer_composer)
                                .set_fee_payer(payer.address)
                                .compose_transaction
```

`set_compute_budget` is a convenience for the same thing, holding the budget as a setting on
the composer instead:

```ruby
tx = Solace::TransactionComposer.new(connection:)
                                .add_instruction(transfer_composer)
                                .set_fee_payer(payer.address)
                                .set_compute_budget(units: 200_000, micro_lamports: 50_000)
                                .compose_transaction
```

When composing, `SetComputeUnitLimit` and `SetComputeUnitPrice` are written first, and any
ComputeBudget composer of the same kind that was added directly is left out — so the budget
cannot be declared twice (a duplicate `SetComputeUnitLimit` fails on chain). Either keyword
may be omitted to set just one; calling it again replaces the budget. `compute_budget` reads
back what is set (`units`, `micro_lamports`, `set?`). With no budget set, directly added
ComputeBudget composers behave as any other instruction.

## Taking a transaction apart

`from` does the reverse of composing: it reads a transaction you were handed — a
`Solace::Transaction` or its base64 — back into an ordinary composer.

```ruby
composer = Solace::TransactionComposer.from(transaction, connection:)

composer.instruction_composers   # one InstructionComposer per instruction, in order
composer.compute_budget          # the limit and price the transaction carried, if any
composer.address_lookup_tables   # its tables, read from chain, with their full address lists
composer.blockhash               # the blockhash it was composed against

composer.set_compute_budget(units: 600_000, micro_lamports: 50_000)
composer.compose_transaction     # composes against that same blockhash by default
```

Each instruction comes back as a [`InstructionComposer`](/building/composers) carrying the
program it invokes, its accounts with the signer and writable flags the message header gave
them, and its data untouched. The rules are Solana's: static keys take their flags from the
header ordering (signers first, writable before read-only, then non-signers the same way);
a v0 message's instruction indexes address the combined space of the static keys, then every
table's writable entries in table order, then every table's read-only entries, and a loaded
address never signs. The tables are read from chain once each and registered, so the
composer composes as v0 again. A table the chain does not hold raises
`Solace::Errors::AddressLookupTableNotFound`.

A `SetComputeUnitLimit` or `SetComputeUnitPrice` the transaction carried becomes the
composer's `compute_budget` rather than an instruction composer, so you can read it and
resize it; any other ComputeBudget directive stays an ordinary instruction.

For a transaction this composer built, `from` then `compose_transaction` answers the same
bytes. A transaction built elsewhere recomposes to the same instructions, accounts and
flags, but may lay the static accounts and table indexes out in a different order.


`compose_transaction` fetches the latest blockhash by default. When you already hold the one
you want — re-composing a transaction you were handed, say, so its expiry stays the same —
pass it in and no fetch happens:

```ruby
tx = Solace::TransactionComposer.new(connection:)
                                .add_instruction(transfer_composer)
                                .set_fee_payer(payer.address)
                                .compose_transaction(blockhash: original.message.recent_blockhash)
```

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

---
title: Account Context
---

# Account Context

`Solace::Utils::AccountContext` is the bookkeeper that turns a set of accounts — each with
its signer/writable flags — into the **ordered account list** and **header** a
[`Message`](/concepts/transactions-and-messages) needs. It is the piece that frees you from
ordering accounts by hand.

Solana requires accounts in a specific order (writable signers, readonly signers, writable
non-signers, readonly non-signers), and the header counts must match. `AccountContext`
collects accounts, deduplicates them, applies the ordering, and computes the header.

## Registering accounts

Each method records an account with a role and returns `self`, so calls chain. Addresses
accept anything `#to_s` (string, `PublicKey`, or `Keypair`).

| Method | Role |
| --- | --- |
| `set_fee_payer(pubkey)` | The fee payer — writable signer, forced to index 0. |
| `add_writable_signer(pubkey)` | Writable, signs. |
| `add_readonly_signer(pubkey)` | Readonly, signs. |
| `add_writable_nonsigner(pubkey)` | Writable, doesn't sign. |
| `add_readonly_nonsigner(pubkey)` | Readonly, doesn't sign (e.g. a program ID). |

If the same address is added more than once, its role is **merged** toward the most
privileged combination (writable wins over readonly, signer over non-signer).

```ruby
context = Solace::Utils::AccountContext.new
context.set_fee_payer(payer)
       .add_writable_nonsigner(recipient)
       .add_readonly_nonsigner(Solace::Constants::SYSTEM_PROGRAM_ID)
       .compile
```

## Compiling

`compile` finalizes the ordering and computes the header. Afterward:

| Accessor / query | Returns | Description |
| --- | --- | --- |
| `accounts` | `Array<String>` | Ordered pubkeys — assign to `Message#accounts`. |
| `header` | `Array<Integer>` | The `[required_sigs, readonly_signed, readonly_unsigned]` header. |
| `index_of(pubkey)` | `Integer` | Position of an address (or `-1` if absent) — feed these to instruction builders. |
| `indices` | `Hash{String=>Integer}` | Every address mapped to its index. |
| `signer?`, `writable?`, `fee_payer?`, … | `Boolean` | Role queries for an address. |

```ruby
ix = Solace::Instructions::SystemProgram::TransferInstruction.build(
  lamports:      1_000_000,
  from_index:    context.index_of(payer),
  to_index:      context.index_of(recipient),
  program_index: context.index_of(Solace::Constants::SYSTEM_PROGRAM_ID)
)
```

## Relocating accounts loaded through lookup tables

For v0 transactions, `relocate_loaded_accounts(writable, readonly)` rebuilds a compiled
account list as `[static..., loaded writable..., loaded readonly...]` — the combined
account space the Solana runtime uses once
[address lookup tables](/concepts/address-lookup-tables) are resolved — and removes the
loaded readonly accounts from the header's readonly-unsigned count. It returns the static
accounts that remain in the message, while `index_of` keeps resolving loaded accounts at
their combined-space positions. The
[`TransactionComposer`](/building/transaction-composer#address-lookup-tables-v0) calls
this for you when lookup tables are in play.

## You usually don't touch it directly

The [`TransactionComposer`](/building/transaction-composer) owns an `AccountContext`
internally: each [composer](/building/composers) registers its accounts into it, then the
composer compiles it and resolves every builder's indices. You reach for `AccountContext`
directly only when assembling a transaction without the composer layer.

`merge_from(other_context)` combines two contexts — the mechanism behind merging composers.

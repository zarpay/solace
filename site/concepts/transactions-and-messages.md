---
title: Transactions & Messages
---

# Transactions & Messages

A `Solace::Transaction` is the thing you submit: a [`Message`](#the-message) plus the
signatures over it. The message carries the instructions, the ordered account list, the
header, and the recent blockhash. These are the lowest-level primitives — deliberately
thin, so you can assemble anything. Most of the time you'll let the
[composer layer](/building/transaction-composer) build them for you.

## The message

```ruby
message = Solace::Message.new(
  version:               nil,  # nil ⇒ legacy; 0 ⇒ versioned (v0)
  header:                [1, 0, 1],
  accounts:              [payer.address, recipient.address, Solace::Constants::SYSTEM_PROGRAM_ID],
  instructions:          [transfer_instruction],
  recent_blockhash:      blockhash,
  address_lookup_tables: []
)
```

The **header** is `[num_required_signatures, num_readonly_signed, num_readonly_unsigned]`
and, with the account ordering, encodes which accounts sign and which are writable. The
account array follows Solana's ordering rule: writable signers, readonly signers, writable
non-signers, then readonly non-signers. Getting this right by hand is exactly what
[`AccountContext`](/concepts/account-context) and the composer layer automate.

| Accessor | Description |
| --- | --- |
| `version` | `nil` for legacy, `0` for v0 (versioned). |
| `header` | The 3-element header array. |
| `accounts` | Ordered base58 pubkeys. |
| `instructions` | Array of [`Instruction`](/concepts/instructions). |
| `recent_blockhash` | Base58 blockhash. |
| `address_lookup_tables` | Array of [`AddressLookupTable`](/concepts/address-lookup-tables) (versioned only). |

Helpers: `versioned?`, `num_required_signatures`, `num_readonly_signed_accounts`,
`num_readonly_unsigned_accounts`.

## The transaction

```ruby
tx = Solace::Transaction.new(message:) # signatures default to []
tx.sign(payer)                         # variadic: tx.sign(payer, cosigner)
tx.signature                           # => first signature (the fee payer's), or nil
base64 = tx.serialize                  # ready for connection.send_transaction
```

`sign` appends a signature per keypair, in fee-payer-first order. `serialize` produces the
base64 wire format; `to_binary` gives the raw bytes.

## Deserializing

Round-trip an encoded transaction back into objects:

```ruby
tx = Solace::Transaction.from(base64_string)
tx.message.instructions
tx.message.accounts
```

This is backed by the [serialization layer](/reference/serialization), which also handles
messages, instructions, and lookup tables.

## Legacy vs. versioned

- **Legacy** (`version: nil`) — the original format; the account list is fully inline.
- **Versioned / v0** (`version: 0`) — adds
  [Address Lookup Tables](/concepts/address-lookup-tables), letting a transaction reference
  many accounts compactly.

Both serialize and deserialize through the same `Transaction`/`Message` classes; the
version flag selects the wire layout.

---
title: Address Lookup Tables
---

# Address Lookup Tables

Address Lookup Tables (ALTs) are a versioned-transaction feature: instead of inlining
every account address in the message, a v0 transaction can reference an on-chain table by
index. This lets one transaction touch far more accounts than the legacy format's size
limit allows.

`Solace::AddressLookupTable` represents the per-transaction reference to such a table — the
table's address plus the indices it contributes.

| Accessor | Type | Description |
| --- | --- | --- |
| `account` | `String` | Base58 address of the on-chain lookup table. |
| `writable_indexes` | `Array<Integer>` | Indices into the table for the writable accounts pulled in. |
| `readonly_indexes` | `Array<Integer>` | Indices for the readonly accounts pulled in. |

```ruby
table = Solace::AddressLookupTable.new
table.account          = lookup_table_address
table.writable_indexes = [1, 2]
table.readonly_indexes = [3, 4]
```

A versioned message carries these in `address_lookup_tables`:

```ruby
message = Solace::Message.new(
  version:               0,           # required: ALTs are a v0 feature
  header:                header,
  accounts:              static_accounts,
  instructions:          instructions,
  recent_blockhash:      blockhash,
  address_lookup_tables: [table]
)
```

ALTs serialize and deserialize through the [serialization layer](/reference/serialization)
(`AddressLookupTable.deserialize(io)` / `#serialize`), the same path used for the rest of
the wire format.

::: tip Scope
Solace models the lookup-table **reference** inside a transaction so it can serialize and
deserialize v0 transactions that use ALTs. Building examples target legacy transactions
unless versioned features are specifically needed; see
[Transactions & Messages](/concepts/transactions-and-messages#legacy-vs-versioned).
:::

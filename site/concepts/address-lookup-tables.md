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

## Composing v0 transactions

You rarely build these references by hand. Register a table on the
[`TransactionComposer`](/building/transaction-composer#address-lookup-tables-v0) and it
selects the loadable accounts, computes the indexes, and emits a v0 message for you:

```ruby
tx = Solace::TransactionComposer.new(connection:)
                                .add_instruction(swap_composer)
                                .set_fee_payer(payer.address)
                                .add_lookup_table(
                                  account:   lookup_table_address,
                                  addresses: on_chain_table_addresses # the table's full address list
                                )
                                .compose_transaction

tx.message.versioned? # => true — registering a table opts into the v0 format
```

The selection follows the runtime rules: signers, the fee payer, and instruction program
ids always stay static; everything else referenced by the transaction and present in a
table is loaded by index.

::: tip Scope
Solace models the lookup-table **reference** inside a transaction — plus the composer
support above for building v0 transactions from tables that already exist on chain.
Creating or extending the on-chain tables themselves (the Address Lookup Table program's
instructions) is not covered; see
[Transactions & Messages](/concepts/transactions-and-messages#legacy-vs-versioned).
:::

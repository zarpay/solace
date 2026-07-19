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

## The on-chain table account

`Solace::Accounts::AddressLookupTable` models the table *account* itself — its address and
the full, ordered list of addresses it stores — as opposed to the per-transaction reference
above. Register one on a composer (address + addresses), or read one from chain:

```ruby
data  = Base64.decode64(connection.get_account_info(table_address)['data'][0])
table = Solace::Accounts::AddressLookupTable.deserialize(StringIO.new(data))

table.authority          # => the table's authority
table.addresses          # => the stored addresses
```

## Composing v0 transactions

You rarely build the reference by hand. Register a table on the
[`TransactionComposer`](/building/transaction-composer#address-lookup-tables-v0) and it
selects the loadable accounts, computes the indexes, and emits a v0 message for you:

```ruby
tx = Solace::TransactionComposer.new(connection:)
                                .add_instruction(swap_composer)
                                .set_fee_payer(payer.address)
                                .add_address_lookup_table(
                                  account:   lookup_table_address,
                                  addresses: on_chain_table_addresses
                                )
                                .compose_transaction
```

The selection follows the runtime rules: signers, the fee payer, and instruction program
ids always stay static; everything else referenced by the transaction and present in a
table is loaded by index.

## Creating and extending tables

Tables are provisioned on chain with the Address Lookup Table program composers. The table
address is a program-derived address of `[authority, recent_slot]`:

```ruby
recent_slot = connection.get_slot - 1
table, bump = Solace::Utils::PDA.find_program_address(
  [authority.address, Solace::Utils::Codecs.encode_le_u64(recent_slot).bytes],
  Solace::Constants::ADDRESS_LOOKUP_TABLE_PROGRAM_ID
)

create_composer = Solace::Composers::AddressLookupTableProgramCreateComposer.new(
  table:       table,
  authority:   authority,
  payer:       authority,
  recent_slot: recent_slot,
  bump:        bump
)

extend_composer = Solace::Composers::AddressLookupTableProgramExtendComposer.new(
  table:     table,
  authority: authority,
  payer:     authority,
  addresses: [address1, address2]
)

tx = Solace::TransactionComposer.new(connection:)
                                .add_instruction(create_composer)
                                .add_instruction(extend_composer)
                                .set_fee_payer(authority)
                                .compose_transaction
```

Addresses added by an extend become usable one slot later. Creating a table is a separate
transaction from composing through it.

::: tip Scope
Solace models the lookup-table **reference** and the on-chain table **account**, composes
v0 transactions through existing tables, and can create and extend tables. Freezing,
deactivating, and closing tables are not yet covered; see
[Transactions & Messages](/concepts/transactions-and-messages#legacy-vs-versioned).
:::

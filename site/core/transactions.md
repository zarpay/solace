# Transactions

A `Solace::Transaction` contains a message and one or more signatures. It is the unit that gets serialized and sent to the network.

## Creating a transaction

```ruby
transaction = Solace::Transaction.new(message: message)
```

## Signing

```ruby
transaction.sign(payer_keypair)
```

Multiple signers:

```ruby
transaction.sign(payer, mint_keypair, authority)
```

## Serializing

`#serialize` returns a Base64-encoded string ready for the `sendTransaction` RPC call:

```ruby
encoded = transaction.serialize
connection.send_transaction(encoded)
```

## Versioned transactions

Solace supports both legacy and versioned (v0) transactions. Versioned transactions can include address lookup tables for larger account sets:

```ruby
message = Solace::Message.new(
  accounts: [...],
  instructions: [...],
  recent_blockhash: blockhash,
  header: [1, 0, 1],
  address_lookup_tables: [lookup_table]
)

transaction = Solace::Transaction.new(message: message)
```

## Low-level vs. composers

Building transactions by hand gives you full control over every field. For most use cases, the [TransactionComposer](/composers/overview) is easier — it handles account ordering and header calculation for you.

---
title: Connection & RPC
---

# Connection & RPC

`Solace::Connection` is the client for a Solana JSON-RPC node. It wraps the HTTP transport
and exposes typed helpers for the calls you need to build, submit, and confirm
transactions.

## Creating a connection

```ruby
connection = Solace::Connection.new(
  'https://api.devnet.solana.com', # positional; default 'http://localhost:8899'
  commitment:        'processed',   # default 'processed'
  http_open_timeout: 30,
  http_read_timeout: 60,
  encoding:          'base64'
)
```

The default URL points at a local validator (`http://localhost:8899`), which is what the
test suite and most examples assume.

## Reading state

| Method | Returns | Description |
| --- | --- | --- |
| `get_balance(pubkey)` | `Integer` | Lamport balance. |
| `get_account_info(pubkey)` | `Hash \| nil` | Raw account, or `nil` if it doesn't exist. |
| `get_multiple_accounts(pubkeys)` | `Array<Hash>` | Several accounts at once. |
| `get_token_account_balance(account)` | `Hash` | `amount` + `decimals` for a token account. |
| `get_token_accounts_by_owner(owner, token_program_id:)` | `Array<Hash>` | An owner's token accounts. |
| `get_mint_program_id(mint)` | `String \| nil` | Which token program owns a mint (SPL vs. Token-2022). |
| `get_minimum_lamports_for_rent_exemption(space)` | `Integer` | Rent-exempt minimum for `space` bytes. |
| `get_program_accounts(program_id, filters)` | `Array` | Accounts owned by a program. |
| `get_block_height(commitment:)` | `Integer` | Current block height (defaults to the connection's commitment). |
| `get_slot(commitment:)` | `Integer` | Current slot (defaults to the connection's commitment). |
| `get_version` / `get_health` / `get_genesis_hash` | varies | Node metadata. |

## Blockhash and rent

A transaction needs a recent blockhash. `get_latest_blockhash` returns a two-element
array — the blockhash and the last valid block height:

```ruby
blockhash, last_valid_height = connection.get_latest_blockhash

# The blockhash stays usable until the chain passes last_valid_height:
connection.get_block_height <= last_valid_height # => true while the blockhash is usable
```

The composer layer fetches this for you; you only call it directly when assembling a
[`Message`](/concepts/transactions-and-messages) by hand. `get_block_height` uses the
connection's commitment by default, so the expiry comparison is apples-to-apples.

## Sending and confirming

```ruby
result = connection.send_transaction(tx.serialize) # accepts base64 or a Transaction
signature = result['result']

connection.wait_for_confirmed_signature('confirmed', timeout: 60, interval: 0.1) do
  signature
end
```

| Method | Description |
| --- | --- |
| `send_transaction(tx, overrides = {})` | Submit a serialized transaction (or a `Transaction`). |
| `simulate_transaction(tx, overrides = {})` | Simulate without committing. |
| `request_airdrop(pubkey, lamports, options = {})` | Fund an account on test clusters. |
| `wait_for_confirmed_signature(commitment = 'confirmed', timeout:, interval:) { … }` | Poll until the yielded signature reaches `commitment`; raises `Solace::Errors::ConfirmationTimeout` on timeout. |

`wait_for_confirmed_signature` takes a block that yields the signature (a `String`, or the
RPC response `Hash` with a `'result'` key) — handy for chaining straight off a
`send_transaction` result.

## Signature status and transactions

```ruby
connection.get_signature_status(signature)
connection.get_signature_statuses([sig_a, sig_b])
connection.get_transaction(signature) # => Solace::Transaction | nil
```

## Errors

RPC and transport failures raise subclasses of `Solace::Errors::Error` —
`ConnectionError`, `HTTPError`, `RPCError`, `ParseError`, and `ConfirmationTimeout`. See
[Errors](/reference/errors).

---
title: Errors
---

# Errors

**`Solace::Errors::TransactionFailed` sits outside `Solace::Errors::Error` and must be
rescued on its own.** A transaction that failed on chain is not a library error, so it is
a plain `StandardError`, and rescuing `Solace::Errors::Error` does not catch it.

Every other Solace error descends from `Solace::Errors::Error`, so you can rescue those
with one class, or catch a specific failure mode. They live under `lib/solace/errors/`.

## Hierarchy

```
StandardError
└─ Solace::Errors::Error
   ├─ Solace::Errors::ConnectionError
   │  ├─ Solace::Errors::HTTPError
   │  └─ Solace::Errors::RPCError
   ├─ Solace::Errors::ParseError
   └─ Solace::Errors::ConfirmationTimeout
StandardError
└─ Solace::Errors::TransactionFailed
```

| Error | Raised when |
| --- | --- |
| `Error` | Base class for every Solace error except `TransactionFailed`. |
| `ConnectionError` | Base for transport/RPC failures. |
| `HTTPError` | A non-success HTTP response from the RPC node (carries `code` and `body`). |
| `RPCError` | The node returned a JSON-RPC error (carries `rpc_code`, `rpc_message`, `rpc_data`). |
| `ParseError` | A response body couldn't be parsed (carries the offending `body`). |
| `ConfirmationTimeout` | `wait_for_confirmed_signature` didn't reach the target commitment in time (carries `signature`, `commitment` — the level awaited — and `timeout`). |
| `TransactionFailed` | Not a `Solace::Errors::Error`. The node reported the transaction `wait_for_confirmed_signature` waited on as failed at `confirmed` or above (carries `signature`, `commitment` — the level awaited, as on `ConfirmationTimeout` — `reported`, the level the node reported the failure at, and the node's `err` as `transaction_error`). |

## Handling them

Rescue broadly, or narrow to the case you care about:

```ruby
begin
  result = connection.send_transaction(tx.serialize)
  connection.wait_for_confirmed_signature { result['result'] }
rescue Solace::Errors::TransactionFailed => e
  warn "Landed but failed: #{e.transaction_error}"
rescue Solace::Errors::ConfirmationTimeout => e
  warn "Not confirmed in #{e.timeout}s: #{e.signature}"
rescue Solace::Errors::RPCError => e
  warn "RPC rejected it (#{e.rpc_code}): #{e.rpc_message}"
rescue Solace::Errors::Error => e
  warn "Solace error: #{e.message}"
end
```

Because `HTTPError` and `RPCError` are both `ConnectionError`, rescuing `ConnectionError`
catches any node-communication problem; rescuing `Solace::Errors::Error` catches that plus
parse and confirmation failures, but never `TransactionFailed`.

---
title: Errors
---

# Errors

All Solace errors descend from `Solace::Errors::Error`, so you can rescue the whole library
with one class — or catch a specific failure mode. They live under `lib/solace/errors/`.

## Hierarchy

```
StandardError
└─ Solace::Errors::Error
   ├─ Solace::Errors::ConnectionError
   │  ├─ Solace::Errors::HTTPError
   │  └─ Solace::Errors::RPCError
   ├─ Solace::Errors::ParseError
   └─ Solace::Errors::ConfirmationTimeout
```

| Error | Raised when |
| --- | --- |
| `Error` | Base class for everything Solace raises. |
| `ConnectionError` | Base for transport/RPC failures. |
| `HTTPError` | A non-success HTTP response from the RPC node (carries `code` and `body`). |
| `RPCError` | The node returned a JSON-RPC error (carries `rpc_code`, `rpc_message`, `rpc_data`). |
| `ParseError` | A response body couldn't be parsed (carries the offending `body`). |
| `ConfirmationTimeout` | `wait_for_confirmed_signature` didn't reach the target commitment in time (carries `signature`, `commitment`, `timeout`). |

## Handling them

Rescue broadly, or narrow to the case you care about:

```ruby
begin
  result = connection.send_transaction(tx.serialize)
  connection.wait_for_confirmed_signature { result['result'] }
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
parse and confirmation failures.

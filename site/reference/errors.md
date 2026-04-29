# Errors

Solace defines a hierarchy of error classes for different failure modes.

## Error hierarchy

```
Solace::Errors::Error (base)
├── Solace::Errors::ConnectionError
│   ├── Solace::Errors::HttpError
│   └── Solace::Errors::ParseError
├── Solace::Errors::RpcError
└── Solace::Errors::ConfirmationTimeout
```

## Error types

### `Solace::Errors::Error`

Base class for all Solace errors. Inherits from `StandardError`.

### `Solace::Errors::ConnectionError`

Raised when a connection to the RPC node fails — network issues, DNS resolution failures, etc.

### `Solace::Errors::HttpError`

A `ConnectionError` subclass raised when the RPC node returns a non-2xx HTTP status.

### `Solace::Errors::ParseError`

A `ConnectionError` subclass raised when the RPC response cannot be parsed as JSON.

### `Solace::Errors::RpcError`

Raised when the RPC node returns a JSON-RPC error response (the request succeeded at the HTTP level but the Solana node rejected it).

### `Solace::Errors::ConfirmationTimeout`

Raised when `wait_for_confirmed_signature` exceeds its timeout waiting for a transaction to reach the requested commitment level.

## Handling errors

```ruby
begin
  response = connection.send_transaction(tx.serialize)
rescue Solace::Errors::RpcError => e
  puts "RPC rejected the transaction: #{e.message}"
rescue Solace::Errors::ConnectionError => e
  puts "Could not reach the RPC node: #{e.message}"
end
```

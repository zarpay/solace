# Serializers

Solace includes serializer/deserializer pairs for converting between Ruby objects and Solana's binary wire format.

## Available serializers

| Class | Serializes |
| --- | --- |
| `TransactionSerializer` / `TransactionDeserializer` | Full transactions (message + signatures) |
| `MessageSerializer` / `MessageDeserializer` | Transaction messages (header + accounts + instructions + blockhash) |
| `InstructionSerializer` / `InstructionDeserializer` | Individual instructions |
| `AddressLookupTableSerializer` / `AddressLookupTableDeserializer` | Address lookup tables (versioned transactions) |

All serializers inherit from `BaseSerializer` / `BaseDeserializer`.

## Serialization

Serialization happens automatically when you call `Transaction#serialize`:

```ruby
encoded = transaction.serialize  # Base64 string
```

Under the hood this calls `TransactionSerializer`, which calls `MessageSerializer`, which calls `InstructionSerializer` for each instruction.

## Deserialization

Parse a Base64-encoded transaction back into Ruby objects:

```ruby
io = Solace::Utils::Codecs.base64_to_bytestream(encoded)
transaction = Solace::Serializers::TransactionDeserializer.deserialize(io)

transaction.message.accounts      # Array of Base58 addresses
transaction.message.instructions  # Array of Instruction objects
```

## Binary format

Solana's wire format uses:

- **Compact u16** for array lengths (ShortVec encoding)
- **Little-endian u64** for amounts
- **32 bytes** for public keys and blockhashes
- **64 bytes** for Ed25519 signatures

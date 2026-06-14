---
title: Codecs
---

# Codecs

`Solace::Utils::Codecs` is the encoding toolbox behind the serializers and instruction
builders: base58/base64 conversions and the little-endian and compact-u16 integer encodings
Solana's binary format uses. All methods are module functions.

## Base58

Solana addresses and signatures are base58.

| Method | Signature | Description |
| --- | --- | --- |
| `bytes_to_base58` | `(Array<Integer>) → String` | Encode a byte array to base58. |
| `base58_to_bytes` | `(String) → Array<Integer>` | Decode base58 to a byte array. |
| `binary_to_base58` | `(String) → String` | Encode a binary string to base58. |
| `base58_to_binary` | `(String) → String` | Decode base58 to a binary string. |
| `valid_base58?` | `(String) → Boolean` | Whether a string is valid base58. |

```ruby
bytes = Solace::Utils::Codecs.base58_to_bytes("11111111111111111111111111111111")
Solace::Utils::Codecs.bytes_to_base58(bytes) # round-trips
```

## Compact-u16 (ShortVec)

Solana encodes array lengths as a variable-length "compact-u16" (ShortVec). Decoders read
from an IO and report how many bytes they consumed.

| Method | Signature | Description |
| --- | --- | --- |
| `encode_compact_u16` | `(Integer) → String` | Encode a length as packed bytes. |
| `decode_compact_u16` | `(IO) → [Integer, Integer]` | Decode `[value, bytes_read]` from a stream. |

```ruby
packed = Solace::Utils::Codecs.encode_compact_u16(300)
value, read = Solace::Utils::Codecs.decode_compact_u16(StringIO.new(packed))
```

## Little-endian u64

Lamport amounts and most numeric instruction arguments are little-endian `u64`.

| Method | Signature | Description |
| --- | --- | --- |
| `encode_le_u64` | `(Integer) → String` | Encode an integer as 8 little-endian bytes. |
| `decode_le_u64` | `(IO) → Integer` | Decode a `u64` from a stream. |

```ruby
data = Solace::Utils::Codecs.encode_le_u64(1_000_000)
```

## Base64

RPC returns account and transaction data as base64; turn it into a stream the deserializers
can read:

| Method | Signature | Description |
| --- | --- | --- |
| `base64_to_bytestream` | `(String) → StringIO` | Decode base64 into a `StringIO`. |

```ruby
io = Solace::Utils::Codecs.base64_to_bytestream(account_info['data'][0])
```

These primitives are what you compose when [writing your own instruction builder](/building/instruction-builders#writing-your-own).

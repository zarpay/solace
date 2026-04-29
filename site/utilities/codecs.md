# Codecs

`Solace::Utils::Codecs` provides encoding and decoding utilities for Solana's binary data formats.

## Base58

```ruby
# Bytes to Base58
base58 = Solace::Utils::Codecs.bytes_to_base58(byte_array)

# Base58 to bytes
bytes = Solace::Utils::Codecs.base58_to_bytes(base58_string)
```

## Base64

```ruby
# Base64 string to IO stream (for deserialization)
io = Solace::Utils::Codecs.base64_to_bytestream(base64_string)
```

## Compact u16 (ShortVec)

Solana uses a variable-length encoding for small integers in serialized data:

```ruby
# Encode
encoded = Solace::Utils::Codecs.encode_compact_u16(1234)

# Decode (from an IO stream)
value, bytes_read = Solace::Utils::Codecs.decode_compact_u16(io)
```

## Little-endian u64

Lamport amounts and other 64-bit values use little-endian encoding:

```ruby
# Encode
encoded = Solace::Utils::Codecs.encode_le_u64(1_000_000_000)

# Decode
value = Solace::Utils::Codecs.decode_le_u64(io)
```

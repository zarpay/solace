---
title: Codecs
---

# Codecs

`Solace::Utils::Codecs` is the encoding toolbox behind the serializers and instruction
builders: base58/base64 conversions, fixed-width and variable-length integers, and the
byte/pubkey/optional collection layouts that Solana programs use. Every method is callable
as a module function (`Solace::Utils::Codecs.encode_le_u64(…)`) and is also available as an
instance method when the module is included into a custom encoder.

## Serialization formats

The helpers cover three distinct binary conventions — the names below are used throughout
this page so you pick the right one:

- **Borsh** — the [Anchor](https://www.anchor-lang.com/) serialization spec. `bool` is a
  single `0`/`1` byte, `Vec<T>`/`bytes` carry a **u32 little-endian** length prefix, and
  `Option<T>` is a 1-byte discriminant (`0` = None, `1` = Some) followed by the value.
- **SmallVec** — a Solana/Anchor-program convention (e.g. Squads) that prefixes a collection
  with a **u8 or u16** length instead of Borsh's u32. _Not_ Borsh.
- **compact-u16 (ShortVec)** — Solana's own variable-length integer used in the transaction
  wire format. _Not_ Borsh.

::: tip Return types
Scalar `encode_le_*` helpers return a binary **String**; the collection/optional/byte helpers
return a byte **Array** so you can concatenate them while assembling instruction data. Every
`decode_*` reads from an `IO`/`StringIO`.
:::

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

## Base64

RPC returns account and transaction data as base64; turn it into a stream the deserializers
can read:

| Method | Signature | Description |
| --- | --- | --- |
| `base64_to_bytestream` | `(String) → StringIO` | Decode base64 into a `StringIO`. |

```ruby
io = Solace::Utils::Codecs.base64_to_bytestream(account_info['data'][0])
```

## Fixed-width little-endian integers

Lamport amounts and most numeric instruction arguments are little-endian. Each `encode`
returns packed bytes; each `decode` reads the matching width from a stream.

| Method | Signature | Description |
| --- | --- | --- |
| `encode_u8` / `decode_u8` | `(Integer) → Array<Integer>` / `(IO) → Integer` | Single unsigned byte. |
| `encode_le_u16` / `decode_le_u16` | `(Integer) → String` / `(IO) → Integer` | Unsigned 16-bit. |
| `encode_le_u32` / `decode_le_u32` | `(Integer) → String` / `(IO) → Integer` | Unsigned 32-bit. |
| `encode_le_u64` / `decode_le_u64` | `(Integer) → String` / `(IO) → Integer` | Unsigned 64-bit (lamports, amounts). |
| `encode_le_u128` / `decode_le_u128` | `(Integer) → String` / `(IO) → Integer` | Unsigned 128-bit. |
| `encode_le_i64` / `decode_le_i64` | `(Integer) → String` / `(IO) → Integer` | Signed 64-bit (two's complement; e.g. timestamps). |
| `encode_bool` | `(Boolean) → Array<Integer>` | Borsh `bool`: `false → 0`, `true → 1`. |

```ruby
data    = Solace::Utils::Codecs.encode_le_u64(1_000_000)
expires = Solace::Utils::Codecs.encode_le_i64(-1)
```

## Compact-u16 (ShortVec)

Solana encodes transaction-level array lengths as a variable-length "compact-u16" (ShortVec).
Decoders read from an IO and report how many bytes they consumed. _This is Solana's wire
format, not Borsh._

| Method | Signature | Description |
| --- | --- | --- |
| `encode_compact_u16` | `(Integer) → String` | Encode a length as packed bytes. |
| `decode_compact_u16` | `(IO) → [Integer, Integer]` | Decode `[value, bytes_read]` from a stream. |

```ruby
packed = Solace::Utils::Codecs.encode_compact_u16(300)
value, read = Solace::Utils::Codecs.decode_compact_u16(StringIO.new(packed))
```

## Byte sequences

Length-prefixed raw bytes. `encode_bytes` is the Borsh `Vec<u8>`/`bytes` layout (u32 prefix);
the `smallvec` variants use the shorter Solana-program prefixes.

| Method | Signature | Description |
| --- | --- | --- |
| `encode_bytes` / `decode_bytes` | `(Array<Integer>) → Array<Integer>` / `(IO) → String` | Borsh `Vec<u8>`: u32 LE length + bytes. |
| `encode_smallvec_u8_bytes` | `(Array<Integer>) → Array<Integer>` | SmallVec: u8 length + bytes (max 255). |
| `encode_smallvec_u16_bytes` | `(Array<Integer>) → Array<Integer>` | SmallVec: u16 LE length + bytes (max 65535). |

```ruby
Solace::Utils::Codecs.encode_bytes([1, 2, 3]) # => [3, 0, 0, 0, 1, 2, 3]
```

## Public keys

A public key is 32 raw bytes (a Solana primitive). Encoders accept any value that resolves to
a base58 string via `#to_s` — a `String`, `Keypair`, or `PublicKey`.

| Method | Signature | Description |
| --- | --- | --- |
| `encode_pubkey` / `decode_pubkey` | `(#to_s) → Array<Integer>` / `(IO) → String` | A single 32-byte key. |
| `encode_vec_pubkeys` / `decode_vec_pubkeys` | `(Array<#to_s>) → Array<Integer>` / `(IO) → Array<String>` | Borsh `Vec<Pubkey>`: u32 count + keys. |
| `encode_smallvec_u8_pubkeys` | `(Array<#to_s>) → Array<Integer>` | SmallVec: u8 count + keys (message header account_keys). |

```ruby
Solace::Utils::Codecs.encode_vec_pubkeys([keypair, "Sysvar1111…"])
```

## Optionals (Borsh `Option<T>`)

A 1-byte discriminant (`0` = None, `1` = Some) followed by the encoded value. Decoders return
`nil` for None.

| Method | Signature | Description |
| --- | --- | --- |
| `encode_option_pubkey` / `decode_option_pubkey` | `(#to_s, nil) → Array<Integer>` / `(IO) → String, nil` | Optional public key. |
| `encode_option_i64` / `decode_option_i64` | `(Integer, nil) → Array<Integer>` / `(IO) → Integer, nil` | Optional signed 64-bit. |
| `encode_option_string` | `(String, nil) → Array<Integer>` | Optional string (Some → u32 length + UTF-8). |

```ruby
Solace::Utils::Codecs.encode_option_i64(nil) # => [0]   (None)
Solace::Utils::Codecs.encode_option_i64(42)  # => [1, …] (Some)
```

These primitives are what you compose when [writing your own instruction builder](/building/instruction-builders#writing-your-own).

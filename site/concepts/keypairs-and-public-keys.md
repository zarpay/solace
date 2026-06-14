---
title: Keypairs & Public Keys
---

# Keypairs & Public Keys

`Solace::Keypair` is an Ed25519 key pair — it holds a private key and can produce
signatures. `Solace::PublicKey` is the 32-byte public half on its own, used wherever an
address is needed but no signing is required.

## Creating a keypair

```ruby
# A fresh random key.
keypair = Solace::Keypair.generate

# From a 32-byte seed (deterministic).
keypair = Solace::Keypair.from_seed(seed_bytes)      # seed must be 32 bytes

# From a 64-byte secret key (seed + public key, the Solana CLI format).
keypair = Solace::Keypair.from_secret_key(secret_key) # must be 64 bytes

# Directly from the 64 raw bytes.
keypair = Solace::Keypair.new(keypair_bytes)
```

`from_seed` and `from_secret_key` raise `ArgumentError` when the input is the wrong length.

## Using a keypair

| Method | Returns | Description |
| --- | --- | --- |
| `public_key` | `Solace::PublicKey` | The public half as a `PublicKey` object. |
| `address` / `to_s` / `to_base58` | `String` | The base58-encoded public key. All three are aliases. |
| `sign(message)` | `String` | The binary Ed25519 signature over `message`. |
| `public_key_bytes` | `Array<Integer>` | The 32 public-key bytes. |
| `private_key_bytes` | `Array<Integer>` | The 32 private-key (seed) bytes. |
| `keypair_bytes` | `Array<Integer>` | All 64 bytes. |

```ruby
keypair = Solace::Keypair.generate

keypair.address          # => "9xQe…" (base58)
signature = keypair.sign("hello")
```

Because `to_s` returns the address, a `Keypair` can be passed anywhere a `#to_s` pubkey
argument is expected (see [Conventions](/conventions#pubkey-arguments-accept-strings-public-keys-or-keypairs)).

## Public keys

```ruby
# From a base58 address.
pubkey = Solace::PublicKey.from_address("9xQe…")

# From 32 raw bytes (Array<Integer> or a 32-byte String).
pubkey = Solace::PublicKey.new(bytes)
```

| Method | Returns | Description |
| --- | --- | --- |
| `to_base58` / `to_s` / `address` | `String` | The base58 address. |
| `to_bytes` | `Array<Integer>` | A copy of the 32 bytes. |
| `bytes` | `Array<Integer>` | The frozen underlying bytes. |
| `==(other)` | `Boolean` | Byte-wise equality with another `PublicKey`. |

Whether an address sits **on** the Ed25519 curve (a wallet) or **off** it (a program
derived address) matters when deriving PDAs — see [PDA Derivation](/reference/pda) and
[Curve25519](/reference/curve25519).

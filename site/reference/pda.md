---
title: PDA Derivation
---

# PDA Derivation

A Program Derived Address (PDA) is an address that lives **off** the Ed25519 curve, so no
private key can sign for it — only its owning program can, via CPI. PDAs are derived
deterministically from a set of seeds and a program ID. `Solace::Utils::PDA` does that
derivation.

## Finding a program address

`find_program_address` searches for the canonical PDA — it appends a "bump" byte and
decrements it until the result is a valid off-curve address.

```ruby
address, bump = Solace::Utils::PDA.find_program_address(
  seeds,      # Array of seeds (see below)
  program_id  # base58 program ID String
)
# => [String, Integer]  — the PDA and its bump seed
```

| Argument | Type | Description |
| --- | --- | --- |
| `seeds` | `Array` | Ordered seeds. Each may be a `String`, an `Integer`, or an `Array<Integer>` of raw bytes. |
| `program_id` | `String` | The program the address is derived for. |

Returns `[address, bump]`. Raises `PDA::InvalidPDAError` if no valid address is found.

### Seed encoding

| Seed type | Encoded as |
| --- | --- |
| `String` | Its bytes — decoded from base58 if it looks like an address, otherwise ASCII. |
| `Integer` | A single byte when `0–255`; otherwise little-endian bytes. |
| `Array<Integer>` | Used directly as raw bytes. |

```ruby
# The Associated Token Account derivation, for example, is:
ata, bump = Solace::Utils::PDA.find_program_address(
  [
    Solace::Utils::Codecs.base58_to_bytes(owner_address),
    Solace::Utils::Codecs.base58_to_bytes(Solace::Constants::TOKEN_PROGRAM_ID),
    Solace::Utils::Codecs.base58_to_bytes(mint_address)
  ],
  Solace::Constants::ASSOCIATED_TOKEN_ACCOUNT_PROGRAM_ID
)
```

## Deriving without a bump search

`create_program_address` derives an address from seeds you supply (including the bump) and
raises `PDA::InvalidPDAError` if the result lands **on** the curve. Use it when you already
know the bump; otherwise use `find_program_address`.

```ruby
address = Solace::Utils::PDA.create_program_address(seeds, program_id)
```

## On-curve vs. off-curve

The search relies on the [Curve25519](/reference/curve25519) check to tell a valid PDA
(off-curve) from a regular address (on-curve). That check is a native extension, so PDA
derivation is fast. Program clients like the [ATA program](/programs/associated-token-account)
wrap these derivations behind named helpers — you rarely call `PDA` directly unless you're
deriving addresses for a program Solace doesn't yet model.

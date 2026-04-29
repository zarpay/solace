# Program Derived Addresses (PDA)

`Solace::Utils::PDA` generates Program Derived Addresses — deterministic addresses derived from seeds and a program ID that do not lie on the Ed25519 curve (so they can't be signed for directly).

## Finding a PDA

```ruby
address, bump = Solace::Utils::PDA.find_program_address(
  ['metadata', mint_address, 'edition'],
  'metaqbxxUerdq28cj1RbAWkYQm3ybzjb6a8bt518x1s'
)
```

`find_program_address` iterates through bump seeds (255 down to 0) until it finds an address that is off-curve. It returns both the address and the bump seed.

## Seed types

Seeds can be:

| Type | Encoding |
| --- | --- |
| `String` | UTF-8 bytes. If the string is a valid Base58 Solana address, it is decoded from Base58 instead. |
| `Integer` | Little-endian byte encoding |
| `Array` | Used as-is (raw bytes) |

## Common PDA patterns

### Associated Token Account

```ruby
ata, _bump = Solace::Utils::PDA.find_program_address(
  [wallet_address, Solace::Constants::TOKEN_PROGRAM_ID, mint_address],
  Solace::Constants::ASSOCIATED_TOKEN_ACCOUNT_PROGRAM_ID
)
```

### Metaplex metadata

```ruby
metadata, _bump = Solace::Utils::PDA.find_program_address(
  ['metadata', 'metaqbxxUerdq28cj1RbAWkYQm3ybzjb6a8bt518x1s', mint_address],
  'metaqbxxUerdq28cj1RbAWkYQm3ybzjb6a8bt518x1s'
)
```

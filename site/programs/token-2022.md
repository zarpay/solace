---
title: Token-2022
---

# Token-2022

`Solace::Programs::Token2022` is the client for the Token-2022 program (Token Extensions).
It shares its entire interface with [`SplToken`](/programs/spl-token) — the same methods,
arguments, composers, and builders — but targets the Token-2022 program ID. The two clients
are interchangeable except for which program they invoke.

```ruby
token2022 = Solace::Programs::Token2022.new(connection:)
```

Program ID: `Solace::Constants::TOKEN_2022_PROGRAM_ID`.

## Same methods as SPL Token

| Method | Composer | Description |
| --- | --- | --- |
| `create_mint` | `compose_create_mint` | Create and initialize a Token-2022 mint. |
| `mint_to` | `compose_mint_to` | Issue supply to a token account. |
| `transfer` | `compose_transfer` | Move tokens. |
| `transfer_checked` | `compose_transfer_checked` | Move tokens with on-chain mint/decimals verification. |
| close account | `Token2022Program…CloseAccountComposer` | Reclaim an empty account's rent. |

All take the shared `sign:`/`execute:` controls and return a `Solace::Transaction`. See the
[SPL Token](/programs/spl-token) page for the full argument tables — they apply verbatim.

```ruby
mint_account = Solace::Keypair.generate

tx = token2022.create_mint(
  payer:          payer,
  funder:         payer,
  decimals:       6,
  mint_authority: payer.address,
  mint_account:   mint_account
)

connection.wait_for_confirmed_signature { tx.signature }
```

## Working across both token programs

A mint belongs to exactly one token program. When you don't know which, ask the connection:

```ruby
program_id = connection.get_mint_program_id(mint)

client =
  if program_id == Solace::Constants::TOKEN_2022_PROGRAM_ID
    Solace::Programs::Token2022.new(connection:)
  else
    Solace::Programs::SplToken.new(connection:)
  end
```

The [Associated Token Account](/programs/associated-token-account) helpers also take a
`token_program_id:` argument so you can derive and create ATAs for Token-2022 mints.

::: tip Token Extensions
Token-2022 adds optional mint/account *extensions* (transfer fees, interest, confidential
transfers, and more). Solace's client covers the core mint-and-transfer operations shared
with SPL Token; configuring extensions is not yet part of the high-level client.
:::

---
layout: home
hero:
  name: Solace
  text: A Ruby SDK for Solana
  tagline: Build, sign, and send Solana transactions from idiomatic Ruby — low-level instruction builders, high-level composers, and program clients, with a native Ed25519/Curve25519 extension.
  actions:
    - theme: brand
      text: Quick Start
      link: /getting-started/
    - theme: alt
      text: Conventions
      link: /conventions
    - theme: alt
      text: View on GitHub
      link: https://github.com/zarpay/solace
---

## What is Solace?

Solace is a Ruby SDK for the [Solana](https://solana.com) blockchain. It follows Ruby
conventions while staying faithful to Solana's binary protocols, and it gives you the
whole stack — from hand-assembling a message byte by byte, to one-call program clients
that derive accounts, sign, and submit for you.

```ruby
require 'solace'

connection = Solace::Connection.new('https://api.mainnet-beta.solana.com')
keypair    = Solace::Keypair.generate

connection.get_balance(keypair.address) # => 0
```

## Four layers, pick your altitude

Solace is organized as four layers. Higher layers are more convenient; lower layers give
you more control. Every operation is reachable at more than one level — see
[Conventions](/conventions).

| Layer | What it is | Reach for it when |
| --- | --- | --- |
| **Program clients** | `Solace::Programs::*` — send-and-sign clients that derive accounts, build, sign, and submit (e.g. `SplToken#create_mint`). | You want one call that does everything. |
| **Composers** | `Solace::Composers::*` — each contributes one instruction to a transaction, managing its own accounts. Assembled by `TransactionComposer`. | You're batching several instructions, or want control over the fee payer and signing. |
| **Instruction builders** | `Solace::Instructions::*` — stateless `.build` methods that encode a single raw instruction from account indices. | You need byte-level control and are assembling the message yourself. |
| **Core primitives** | `Keypair`, `PublicKey`, `Connection`, `Transaction`, `Message`, `Instruction`, `AccountContext`. | The foundation everything else is built on. |

## What's covered

- **Core primitives** — [keypairs & public keys](/concepts/keypairs-and-public-keys),
  [connection & RPC](/concepts/connection-and-rpc),
  [transactions & messages](/concepts/transactions-and-messages) (legacy and versioned),
  [instructions](/concepts/instructions), [account context](/concepts/account-context),
  and [address lookup tables](/concepts/address-lookup-tables).
- **Building transactions** — [instruction builders](/building/instruction-builders),
  [composers](/building/composers), the
  [transaction composer](/building/transaction-composer), and
  [program clients](/building/program-clients).
- **Programs** — the [System Program](/programs/system-program),
  [SPL Token](/programs/spl-token), [Token-2022](/programs/token-2022), the
  [Associated Token Account](/programs/associated-token-account) program, and
  [Compute Budget](/programs/compute-budget).
- **Reference** — [codecs](/reference/codecs), [PDA derivation](/reference/pda),
  [Curve25519](/reference/curve25519), [constants](/reference/constants),
  [serialization](/reference/serialization), [tokens](/reference/tokens), and
  [errors](/reference/errors).

## Extending Solace

Solace is designed to be extended. The [Squads Smart Accounts](https://github.com/zarpay/solace-squads-smart-accounts)
gem adds the Squads Smart Account program by following the same instruction-builder →
composer → program-client pattern documented here. The [Building Transactions](/building/instruction-builders)
section is the blueprint for writing your own program support.

## Install

```ruby
# Gemfile
gem 'solace'
```

```sh
bundle install
```

Native binaries for the Curve25519 operations ship with the gem for Linux, macOS, and
Windows (x86_64 and ARM64) — there is nothing to compile.

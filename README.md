# Solace

[![Gem Version](https://img.shields.io/gem/v/solace.svg)](https://rubygems.org/gems/solace)
[![CI](https://github.com/zarpay/solace/actions/workflows/main.yml/badge.svg)](https://github.com/zarpay/solace/actions/workflows/main.yml)
[![Docs](https://img.shields.io/badge/docs-zarpay.github.io-7c3aed.svg)](https://zarpay.github.io/solace)
[![License: MIT](https://img.shields.io/badge/license-MIT-yellow.svg)](LICENSE)
[![Ruby](https://img.shields.io/badge/ruby-%E2%89%A5%203.0-CC342D.svg)](https://www.ruby-lang.org/)

A Ruby SDK for the [Solana](https://solana.com) blockchain. Solace lets you build, sign,
and send Solana transactions from idiomatic Ruby — from hand-assembling a message byte by
byte, up to one-call program clients that derive accounts, sign, and submit for you. It
ships a native Ed25519/Curve25519 extension (prebuilt for Linux, macOS, and Windows), so
there's nothing to compile.

📖 **Documentation:** **https://zarpay.github.io/solace**

The gem lives in [`gem/`](gem/); the documentation site (VitePress) lives in
[`site/`](site/).

## Quick start

```ruby
require 'solace'

connection = Solace::Connection.new('https://api.devnet.solana.com')
payer      = Solace::Keypair.generate
recipient  = Solace::Keypair.generate

# Compose, sign, and send a SOL transfer.
tx = Solace::TransactionComposer.new(connection:)
                                .add_instruction(
                                  Solace::Composers::SystemProgramTransferComposer.new(
                                    from:     payer.address,
                                    to:       recipient.address,
                                    lamports: 1_000_000
                                  )
                                )
                                .set_fee_payer(payer.address)
                                .compose_transaction

tx.sign(payer)
result = connection.send_transaction(tx.serialize)
connection.wait_for_confirmed_signature { result['result'] }
```

See the [Quick Start guide](https://zarpay.github.io/solace/getting-started/) for the full
walkthrough.

## Four layers, pick your altitude

Solace is organized as four layers — higher layers are more convenient, lower layers give
more control. Every operation is reachable at more than one level.

| Layer | What it is |
| --- | --- |
| **Program clients** (`Solace::Programs::*`) | Send-and-sign clients that derive accounts, build, sign, and submit (e.g. `SplToken#create_mint`). |
| **Composers** (`Solace::Composers::*`) | Each contributes one instruction to a transaction, managing its own accounts; assembled by `TransactionComposer`. |
| **Instruction builders** (`Solace::Instructions::*`) | Stateless `.build` methods that encode a single raw instruction from account indices. |
| **Core primitives** | `Keypair`, `PublicKey`, `Connection`, `Transaction`, `Message`, `Instruction`, `AccountContext`. |

## What's covered

- **Core primitives** — keypairs & public keys, the RPC connection, transactions and
  messages (legacy and versioned), instructions, account context, and address lookup tables.
- **Building transactions** — instruction builders, composers, the transaction composer,
  and program clients.
- **Programs** — the System program, SPL Token, Token-2022, the Associated Token
  Account program, and Compute Budget.
- **Reference** — codecs, PDA derivation, Curve25519, constants, serialization, tokens, and
  errors.

Full documentation per topic lives on the [docs site](https://zarpay.github.io/solace).

## Install

```ruby
# Gemfile
gem 'solace'
```

```sh
bundle install
```

Native binaries for the Curve25519 operations ship with the gem for Linux, macOS, and
Windows (x86_64 and ARM64).

## Development

The gem lives in `gem/`; run all gem commands from there:

```sh
cd gem
bundle install
bundle exec rake bootstrap   # start a solana-test-validator and fund the fixture accounts
bundle exec rake test        # run the test suite against the funded validator
bundle exec rubocop          # lint
```

Tests run against a local `solana-test-validator`. Run `rake bootstrap` once to fund the
fixture keypairs (the funded ledger persists in `test-ledger/`), then `rake test`.

The native Rust extension is prebuilt and committed under `gem/lib/solace/utils/`; rebuild
it with `rake compile` (needs a Rust toolchain) or the `build-libs` GitHub Actions workflow.

The documentation site is a [VitePress](https://vitepress.dev/) app in `site/`:

```sh
cd site
npm install
npm run dev     # local preview
npm run build   # static build
```

## License

Released under the [MIT License](LICENSE).

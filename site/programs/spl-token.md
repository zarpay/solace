---
title: SPL Token
---

# SPL Token

`Solace::Programs::SplToken` is the send-and-sign client for the SPL Token program —
create mints, mint supply, and move tokens. Each method has a `compose_*` sibling that
returns a [`TransactionComposer`](/building/transaction-composer) instead of submitting, and
is backed by an [instruction builder](/building/instruction-builders) under
`Instructions::SplToken`.

```ruby
spl = Solace::Programs::SplToken.new(connection:)
```

Program ID: `Solace::Constants::TOKEN_PROGRAM_ID`. All methods take the shared
`sign:`/`execute:` controls and return a `Solace::Transaction` — see
[Conventions](/conventions#signing-and-sending). Pubkey arguments accept a String,
`PublicKey`, or `Keypair` (`#to_s`).

## Create a mint

Creates and initializes a new token mint in one transaction.

### Program method — `create_mint`

| Parameter | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `payer` | Keypair | yes | — | Pays the fee; co-signs. |
| `funder` | #to_s · Keypair | yes | — | Funds the mint account's rent. |
| `decimals` | Integer | yes | — | Decimal places for the token. |
| `mint_authority` | #to_s | yes | — | Authority allowed to mint new supply. |
| `freeze_authority` | #to_s | no | `nil` | Authority allowed to freeze accounts. |
| `mint_account` | Keypair | no | `Keypair.generate` | The mint's keypair; co-signs. |

```ruby
mint_account = Solace::Keypair.generate

tx = spl.create_mint(
  payer:          payer,
  funder:         payer,
  decimals:       6,
  mint_authority: payer.address,
  mint_account:   mint_account
)

connection.wait_for_confirmed_signature { tx.signature }
mint = mint_account.address
```

### Composer — `compose_create_mint`

Returns a `TransactionComposer` (drop the `payer`/`sign`/`execute` controls). Compose,
sign with both the funder and the mint keypair, and send:

```ruby
mint_account = Solace::Keypair.generate

tx = spl.compose_create_mint(
         funder:         payer,
         decimals:       6,
         mint_authority: payer.address,
         mint_account:   mint_account
       )
       .set_fee_payer(payer.address)
       .compose_transaction

tx.sign(payer, mint_account)
connection.send_transaction(tx.serialize)
```

### Low-level instruction (advanced)

Creating a mint is two instructions: `SystemProgram::CreateAccountInstruction` (allocate
the mint account, owned by the token program) followed by
`Instructions::SplToken::InitializeMintInstruction.build` (set decimals and authorities).
The composer assembles both; reach for the builders directly only when hand-assembling the
message.

## Mint to an account

### Program method — `mint_to`

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `payer` | Keypair | yes | Pays the fee; co-signs. |
| `mint` | #to_s | yes | The mint to issue from. |
| `destination` | #to_s | yes | Token account to credit. |
| `amount` | Integer | yes | Base units to mint (respecting `decimals`). |
| `mint_authority` | #to_s · Keypair | yes | The mint authority; co-signs. |

```ruby
tx = spl.mint_to(
  payer:          payer,
  mint:           mint,
  destination:    token_account,
  amount:         1_000_000,
  mint_authority: payer
)
```

Composer: `compose_mint_to(mint:, destination:, amount:, mint_authority:)`. Builder:
`Instructions::SplToken::MintToInstruction`.

## Transfer tokens

### Program method — `transfer`

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `payer` | Keypair | yes | Pays the fee; co-signs. |
| `source` | #to_s | yes | Source token account. |
| `destination` | #to_s | yes | Destination token account. |
| `amount` | Integer | yes | Base units to transfer. |
| `owner` | #to_s · Keypair | yes | Owner/authority of the source account; co-signs. |

```ruby
tx = spl.transfer(
  payer:       payer,
  source:      sender_ata,
  destination: recipient_ata,
  amount:      500_000,
  owner:       payer
)
```

Composer: `compose_transfer(source:, destination:, amount:, owner:)`. Builder:
`Instructions::SplToken::TransferInstruction`.

## Transfer (checked)

`transfer_checked` is the safe variant — it verifies the mint and decimals on-chain.

### Program method — `transfer_checked`

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `payer` | Keypair | yes | Pays the fee; co-signs. |
| `from` | #to_s | yes | Source token account. |
| `to` | #to_s | yes | Destination token account. |
| `mint` | #to_s | yes | The token's mint. |
| `amount` | Integer | yes | Base units to transfer. |
| `decimals` | Integer | yes | The mint's decimals (verified on-chain). |
| `authority` | #to_s · Keypair | yes | Owner/authority of `from`; co-signs. |

```ruby
tx = spl.transfer_checked(
  payer:     payer,
  from:      sender_ata,
  to:        recipient_ata,
  mint:      mint,
  amount:    500_000,
  decimals:  6,
  authority: payer
)
```

Composer: `compose_transfer_checked(from:, to:, mint:, amount:, decimals:, authority:)`.
Builder: `Instructions::SplToken::TransferCheckedInstruction`.

## Close an account

Reclaim a token account's rent once it's empty. Composer:
`SplTokenProgramCloseAccountComposer`; builder:
`Instructions::SplToken::CloseAccountInstruction`.

## End-to-end

```ruby
spl = Solace::Programs::SplToken.new(connection:)
ata = Solace::Programs::AssociatedTokenAccount.new(connection:)

# 1. Create a mint.
mint_account = Solace::Keypair.generate
tx = spl.create_mint(payer:, funder: payer, decimals: 6, mint_authority: payer.address, mint_account:)
connection.wait_for_confirmed_signature { tx.signature }
mint = mint_account.address

# 2. Ensure token accounts exist (see Associated Token Account).
sender_ata    = ata.get_or_create_address(payer:, funder: payer, owner: payer, mint:)
recipient     = Solace::Keypair.generate
recipient_ata = ata.get_or_create_address(payer:, funder: payer, owner: recipient, mint:)

# 3. Mint, then transfer.
spl.mint_to(payer:, mint:, destination: sender_ata, amount: 1_000_000, mint_authority: payer)
spl.transfer_checked(payer:, from: sender_ata, to: recipient_ata, mint:, amount: 500_000, decimals: 6, authority: payer)
```

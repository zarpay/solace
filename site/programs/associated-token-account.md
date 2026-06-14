---
title: Associated Token Account
---

# Associated Token Account

An Associated Token Account (ATA) is the canonical token account for a given
`(owner, mint)` pair — a [PDA](/reference/pda) anyone can derive, so wallets agree on where
to send tokens. `Solace::Programs::AssociatedTokenAccount` derives those addresses and
creates the accounts on chain.

```ruby
ata = Solace::Programs::AssociatedTokenAccount.new(connection:)
```

Program ID: `Solace::Constants::ASSOCIATED_TOKEN_ACCOUNT_PROGRAM_ID`. Every method takes a
`token_program_id:` so it works for both [SPL Token](/programs/spl-token) and
[Token-2022](/programs/token-2022) mints.

## Derive an ATA address

`get_address` is pure derivation — no network call. It's available as both a class method
and an instance method.

| Parameter | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `owner` | #to_s | yes | — | The token account's owner. |
| `mint` | #to_s | yes | — | The token mint. |
| `token_program_id` | #to_s | no | `TOKEN_PROGRAM_ID` | The token program (use `TOKEN_2022_PROGRAM_ID` for Token-2022 mints). |

```ruby
address, bump = Solace::Programs::AssociatedTokenAccount.get_address(
  owner: owner.address,
  mint:  mint
)
```

## Get or create

`get_or_create_address` returns the ATA address, creating the account first if it doesn't
exist (and waiting for confirmation). This is the method you'll reach for most.

| Parameter | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `payer` | Keypair | yes | — | Pays the fee if creation is needed; co-signs. |
| `funder` | #to_s · Keypair | yes | — | Funds the new account's rent. |
| `owner` | #to_s | yes | — | The account's owner. |
| `mint` | #to_s | yes | — | The token mint. |
| `token_program_id` | #to_s | no | `TOKEN_PROGRAM_ID` | The token program. |

```ruby
address = ata.get_or_create_address(
  payer:  payer,
  funder: payer,
  owner:  owner.address,
  mint:   mint
)
# => base58 ATA address; the account now exists on chain
```

## Create explicitly

When you want a transaction rather than the get-or-create convenience:

### Program method — `create_associated_token_account`

| Parameter | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `payer` | Keypair | yes | — | Pays the fee; co-signs. |
| `funder` | #to_s · Keypair | yes | — | Funds the new account's rent. |
| `owner` | #to_s | yes | — | The account's owner. |
| `mint` | #to_s | yes | — | The token mint. |
| `token_program_id` | #to_s | no | `TOKEN_PROGRAM_ID` | The token program. |

Plus the shared `sign:`/`execute:` controls and `Solace::Transaction` return.

```ruby
tx = ata.create_associated_token_account(
  payer:  payer,
  funder: payer,
  owner:  owner.address,
  mint:   mint
)
```

### Composer — `compose_create_associated_token_account`

Returns a [`TransactionComposer`](/building/transaction-composer):

```ruby
tx = ata.compose_create_associated_token_account(
       funder: payer,
       owner:  owner.address,
       mint:   mint
     )
     .set_fee_payer(payer.address)
     .compose_transaction

tx.sign(payer)
connection.send_transaction(tx.serialize)
```

### Low-level instruction (advanced)

Two builders back the ATA program:

- `Instructions::AssociatedTokenAccount::CreateAccountInstruction` — fails if the account
  already exists.
- `Instructions::AssociatedTokenAccount::CreateIdempotentAccountInstruction` — succeeds
  whether or not the account exists, the safe choice when several flows might create the
  same ATA.

Both are also available as composers
(`AssociatedTokenAccountProgramCreateAccountComposer` and
`AssociatedTokenAccountProgramCreateIdempotentAccountComposer`).

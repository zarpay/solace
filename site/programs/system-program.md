---
title: System Program
---

# System Program

The System program owns the most fundamental operations: transferring SOL and creating
accounts. Solace ships [instruction builders](/building/instruction-builders) and
[composers](/building/composers) for both. There is no dedicated `Programs::System` client —
these operations are simple enough that the composer layer is the natural top level.

Program ID: `Solace::Constants::SYSTEM_PROGRAM_ID` (`11111111111111111111111111111111`).

## Transfer SOL

Move lamports from one account to another.

### Composer — `SystemProgramTransferComposer`

| Parameter | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `from` | #to_s | yes | — | Source account (writable signer). |
| `to` | #to_s | yes | — | Destination account (writable). |
| `lamports` | Integer | yes | — | Amount to transfer, in lamports. |

```ruby
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
connection.send_transaction(tx.serialize)
```

### Low-level instruction (advanced)

`Instructions::SystemProgram::TransferInstruction.build` encodes the raw instruction from
account indices.

- **Encodes (`data`):** `le_u32(2)` (the System `Transfer` discriminator) + `le_u64(lamports)`

| Parameter | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `lamports` | Integer | yes | — | Amount in lamports. |
| `from_index` | Integer | yes | — | Index of the source account. |
| `to_index` | Integer | yes | — | Index of the destination account. |
| `program_index` | Integer | no | `2` | Index of the System program in the account list. |

```ruby
ix = Solace::Instructions::SystemProgram::TransferInstruction.build(
  lamports:      1_000_000,
  from_index:    context.index_of(payer.address),
  to_index:      context.index_of(recipient.address),
  program_index: context.index_of(Solace::Constants::SYSTEM_PROGRAM_ID)
)
```

## Create an account

Allocate a new account, fund it to rent-exemption, and assign it to an owning program —
the primitive behind creating mints, token accounts, and program state.

### Composer — `SystemProgramCreateAccountComposer`

| Parameter | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `from` | #to_s | yes | — | Funder of the new account's rent (writable signer). |
| `new_account` | #to_s | yes | — | The account to create (writable signer). |
| `lamports` | Integer | yes | — | Lamports to deposit (use `get_minimum_lamports_for_rent_exemption`). |
| `space` | Integer | yes | — | Bytes to allocate for the account's data. |
| `owner` | #to_s | yes | — | Program that will own the new account. |

```ruby
rent  = connection.get_minimum_lamports_for_rent_exemption(165)
acct  = Solace::Keypair.generate

tx = Solace::TransactionComposer.new(connection:)
                                .add_instruction(
                                  Solace::Composers::SystemProgramCreateAccountComposer.new(
                                    from:        payer.address,
                                    new_account: acct.address,
                                    lamports:    rent,
                                    space:       165,
                                    owner:       Solace::Constants::TOKEN_PROGRAM_ID
                                  )
                                )
                                .set_fee_payer(payer.address)
                                .compose_transaction

tx.sign(payer, acct) # the new account must also sign
connection.send_transaction(tx.serialize)
```

### Low-level instruction (advanced)

`Instructions::SystemProgram::CreateAccountInstruction.build` encodes the raw instruction.

- **Encodes (`data`):** `le_u32(0)` (the System `CreateAccount` discriminator) +
  `le_u64(lamports)` + `le_u64(space)` + the 32-byte `owner` pubkey.

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `lamports` | Integer | yes | Rent to deposit. |
| `space` | Integer | yes | Bytes to allocate. |
| `owner` | #to_s | yes | Owning program's pubkey. |
| `from_index` | Integer | yes | Index of the funder. |
| `new_account_index` | Integer | yes | Index of the new account. |
| `program_index` | Integer | yes | Index of the System program. |

::: tip
Creating a mint or token account combines a create-account instruction with an initialize
instruction in one transaction. The [SPL Token](/programs/spl-token) client does this for
you in `create_mint`.
:::

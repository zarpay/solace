---
title: Composers
---

# Composers

A composer wraps a single instruction at a friendlier altitude than an
[instruction builder](/building/instruction-builders). It takes account **addresses**
instead of indices, knows which of its accounts are signers and which are writable, and
registers them with the shared [`AccountContext`](/concepts/account-context). You hand
composers to a [`TransactionComposer`](/building/transaction-composer), which orders the
accounts and resolves every index for you.

Composers live under `lib/solace/composers/` and subclass `Solace::Composers::Base`.

## Using a composer

```ruby
composer = Solace::Composers::SystemProgramTransferComposer.new(
  from:     payer.address, # #to_s — String, PublicKey, or Keypair
  to:       recipient.address,
  lamports: 1_000_000
)

tx = Solace::TransactionComposer.new(connection:)
                                .add_instruction(composer)
                                .set_fee_payer(payer.address)
                                .compose_transaction
```

You construct composers with addresses and domain arguments; you never compute indices.

## Bundled composers

| Program | Composers |
| --- | --- |
| **System** | `SystemProgramTransferComposer`, `SystemProgramCreateAccountComposer` |
| **SPL Token** | `SplTokenProgramInitializeMintComposer`, `SplTokenProgramMintToComposer`, `SplTokenProgramTransferComposer`, `SplTokenProgramTransferCheckedComposer`, `SplTokenProgramCloseAccountComposer` |
| **Token-2022** | `Token2022Program…` — the same set for the Token-2022 program |
| **Associated Token Account** | `AssociatedTokenAccountProgramCreateAccountComposer`, `AssociatedTokenAccountProgramCreateIdempotentAccountComposer` |
| **Compute Budget** | `ComputeBudgetProgramSetComputeUnitPriceComposer`, `ComputeBudgetProgramSetComputeUnitLimitComposer` |

## The Base contract

`Solace::Composers::Base` defines the two-method protocol every composer implements; the
`TransactionComposer` calls them in order:

| Method | Called | Responsibility |
| --- | --- | --- |
| `setup_accounts` | at construction | Register this instruction's accounts on `account_context` with the right roles. |
| `build_instruction(account_context)` | during `compose_transaction` | Return a `Solace::Instruction` (or an array of them), resolving indices via `account_context.index_of(...)`. |

| Accessor | Description |
| --- | --- |
| `params` | The constructor keyword arguments. |
| `account_context` | This composer's local `AccountContext` (merged into the transaction's). |

## Writing your own

```ruby
class MyTransferComposer < Solace::Composers::Base
  def setup_accounts
    account_context.add_writable_signer(params[:from])
    account_context.add_writable_nonsigner(params[:to])
    account_context.add_readonly_nonsigner(Solace::Constants::SYSTEM_PROGRAM_ID)
  end

  def build_instruction(account_context)
    Solace::Instructions::SystemProgram::TransferInstruction.build(
      lamports:      params[:lamports],
      from_index:    account_context.index_of(params[:from]),
      to_index:      account_context.index_of(params[:to]),
      program_index: account_context.index_of(Solace::Constants::SYSTEM_PROGRAM_ID)
    )
  end
end
```

That's the entire pattern: declare accounts, then build from resolved indices. It's also
how extension gems add new programs — see the
[Squads Smart Accounts](https://github.com/zarpay/solace-squads-smart-accounts) gem.

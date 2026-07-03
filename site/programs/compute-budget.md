---
title: Compute Budget
---

# Compute Budget

The Compute Budget program prices and provisions a transaction's execution — most
importantly the priority fee validators use to order transactions during congestion.
Solace ships an [instruction builder](/building/instruction-builders) and a
[composer](/building/composers) for setting the compute unit price. There is no dedicated
`Programs::ComputeBudget` client — the instruction only ever rides along in another
transaction, so the composer layer is the natural top level.

Program ID: `Solace::Constants::COMPUTE_BUDGET_PROGRAM_ID` (`ComputeBudget111111111111111111111111111111`).

## Set compute unit price

Attach a priority fee, priced in micro-lamports per compute unit. The total priority fee a
transaction pays is this price multiplied by its compute unit limit.

### Composer — `ComputeBudgetProgramSetComputeUnitPriceComposer`

| Parameter | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `micro_lamports` | Integer | yes | — | Price per compute unit, in micro-lamports. |

```ruby
tx = Solace::TransactionComposer.new(connection:)
                                .add_instruction(
                                  Solace::Composers::ComputeBudgetProgramSetComputeUnitPriceComposer.new(
                                    micro_lamports: 50_000
                                  )
                                )
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

`Instructions::ComputeBudget::SetComputeUnitPriceInstruction.build` encodes the raw
instruction. It references no accounts — only the program itself.

- **Encodes (`data`):** `u8(3)` (the `SetComputeUnitPrice` discriminator) +
  `le_u64(micro_lamports)`

| Parameter | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `micro_lamports` | Integer | yes | — | Price per compute unit, in micro-lamports. |
| `program_index` | Integer | yes | — | Index of the Compute Budget program in the account list. |

```ruby
ix = Solace::Instructions::ComputeBudget::SetComputeUnitPriceInstruction.build(
  micro_lamports: 50_000,
  program_index:  context.index_of(Solace::Constants::COMPUTE_BUDGET_PROGRAM_ID)
)
```

::: tip
Compute Budget instructions conventionally sit first in a transaction — use
`prepend_instruction` on the [transaction composer](/building/transaction-composer) to
slot the priority fee ahead of instructions you've already added.
:::

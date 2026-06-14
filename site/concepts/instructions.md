---
title: Instructions
---

# Instructions

A `Solace::Instruction` is a single operation inside a transaction. It is intentionally
minimal — three fields, all indices and bytes:

| Accessor | Type | Description |
| --- | --- | --- |
| `program_index` | `Integer` | Index (into the message's account list) of the program to invoke. |
| `accounts` | `Array<Integer>` | Indices of the accounts this instruction touches, in the order the program expects. |
| `data` | `Array<Integer>` | The instruction payload — opcode/discriminator plus encoded arguments. |

Note that an instruction refers to accounts by **position**, not by address. The addresses
live once in `Message#accounts`; every instruction points into that list. This is what
keeps transactions compact, and why account ordering is load-bearing (see
[Account Context](/concepts/account-context)).

## Building one by hand

```ruby
ix = Solace::Instruction.new
ix.program_index = 2
ix.accounts      = [0, 1]
ix.data          = [2, 0, 0, 0, 0, 64, 66, 15, 0, 0, 0, 0] # transfer 1_000_000 lamports
```

You rarely write the `data` bytes yourself. That's what
[instruction builders](/building/instruction-builders) are for — each encodes the
discriminator and arguments for one program instruction:

```ruby
ix = Solace::Instructions::SystemProgram::TransferInstruction.build(
  lamports:      1_000_000,
  from_index:    0,
  to_index:      1,
  program_index: 2
)
# => Solace::Instruction
```

## Where instructions come from

| Source | Gives you | When |
| --- | --- | --- |
| `Instruction.new` | A blank instruction to fill in. | You're encoding `data` yourself. |
| `Instructions::*.build` | A fully-encoded instruction from **indices**. | You manage account ordering. |
| A [composer](/building/composers) | An instruction from **addresses**, plus account registration. | You let `TransactionComposer` order accounts. |

Whichever you use, the result is the same `Instruction` object that goes into
`Message#instructions`.

---
title: Instruction Builders
---

# Instruction Builders

Instruction builders are the lowest assembly layer. Each is a stateless service object with
a single `.build` class method that encodes **one** program instruction — the discriminator
plus its arguments — and returns a [`Solace::Instruction`](/concepts/instructions). They
live under `lib/solace/instructions/`, grouped by program.

Builders take account **indices**, not addresses: you own the message's account ordering
(typically via an [`AccountContext`](/concepts/account-context)). That control is the whole
point of this layer; if you'd rather pass addresses and let the ordering be computed, use a
[composer](/building/composers).

## The shape of a builder

```ruby
ix = Solace::Instructions::SystemProgram::TransferInstruction.build(
  lamports:      1_000_000,
  from_index:    0, # index into Message#accounts
  to_index:      1,
  program_index: 2  # index of the System program in the account list
)
# => Solace::Instruction
```

Every builder follows the same convention: domain arguments (here `lamports`) plus
`*_index` arguments for each account it references, and a `program_index` for the invoked
program. The returned instruction's `data` is the fully-encoded byte payload.

## Bundled builders

| Program | Builders |
| --- | --- |
| **System** (`Instructions::SystemProgram`) | `TransferInstruction`, `CreateAccountInstruction` |
| **SPL Token** (`Instructions::SplToken`) | `InitializeMintInstruction`, `InitializeAccountInstruction`, `MintToInstruction`, `TransferInstruction`, `TransferCheckedInstruction`, `CloseAccountInstruction` |
| **Token-2022** (`Instructions::Token2022`) | the same set as SPL Token, targeting the Token-2022 program |
| **Associated Token Account** (`Instructions::AssociatedTokenAccount`) | `CreateAccountInstruction`, `CreateIdempotentAccountInstruction` |

## Resolving indices

In practice you pair a builder with an `AccountContext` so you never hard-code positions:

```ruby
context = Solace::Utils::AccountContext.new
context.set_fee_payer(payer)
       .add_writable_nonsigner(recipient)
       .add_readonly_nonsigner(Solace::Constants::SYSTEM_PROGRAM_ID)
       .compile

ix = Solace::Instructions::SystemProgram::TransferInstruction.build(
  lamports:      1_000_000,
  from_index:    context.index_of(payer),
  to_index:      context.index_of(recipient),
  program_index: context.index_of(Solace::Constants::SYSTEM_PROGRAM_ID)
)
```

## Writing your own

A builder is just a class with a `.build` that returns an `Instruction`. Encode the
discriminator and arguments with the [codecs](/reference/codecs)
(`encode_le_u64`, `encode_compact_u16`, …), set `program_index`/`accounts`/`data`, and
return it. This is the foundation the [composer](/building/composers) layer sits on, and the
pattern extension gems follow to add new programs.

# Instructions

A `Solace::Instruction` represents a single operation within a transaction. It references accounts by index and carries a binary data payload.

## Structure

```ruby
instruction = Solace::Instruction.new(
  program_index: 2,              # Index of the program in the accounts array
  accounts: [0, 1],              # Indices of referenced accounts
  data: [2, 0, 0, 0] + amount   # Instruction data bytes
)
```

### Fields

| Field | Type | Description |
| --- | --- | --- |
| `program_index` | Integer | Index of the executing program in the message's accounts array |
| `accounts` | Array&lt;Integer&gt; | Indices of accounts this instruction reads or writes |
| `data` | Array&lt;Integer&gt; | Raw instruction data (byte array) |

## Instruction builders

Solace ships instruction builders that handle binary encoding for common Solana programs:

```ruby
# System Program — SOL transfer
Solace::Instructions::SystemProgram::TransferInstruction.build(
  lamports: 1_000_000,
  from_index: 0,
  to_index: 1,
  program_index: 2
)

# System Program — create account
Solace::Instructions::SystemProgram::CreateAccountInstruction.build(
  lamports: rent_amount,
  space: 82,
  owner: Solace::Constants::TOKEN_PROGRAM_ID,
  from_index: 0,
  to_index: 1,
  program_index: 2
)

# SPL Token — transfer
Solace::Instructions::SplToken::TransferInstruction.build(
  amount: 1_000_000,
  from_index: 0,
  to_index: 1,
  authority_index: 2,
  program_index: 3
)
```

### Available builders

- `SystemProgram::TransferInstruction`
- `SystemProgram::CreateAccountInstruction`
- `SplToken::InitializeMintInstruction`
- `SplToken::InitializeAccountInstruction`
- `SplToken::MintToInstruction`
- `SplToken::TransferInstruction`
- `SplToken::TransferCheckedInstruction`
- `SplToken::CloseAccountInstruction`
- `AssociatedTokenAccount::CreateAccountInstruction`
- `AssociatedTokenAccount::CreateIdempotentAccountInstruction`

### Conventions

All builders follow the same pattern:

- `.build()` class method returns a `Solace::Instruction`
- `.data()` returns just the encoded data bytes
- Account parameters use an `_index` suffix
- Every builder takes a `program_index` parameter

## When to use directly

Instruction builders are useful when you need to assemble transactions by hand. For most use cases, prefer [Composers](/composers/overview) — they handle account ordering and index calculation automatically.

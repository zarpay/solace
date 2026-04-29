# Composers

Composers are the recommended way to build transactions in Solace. A `TransactionComposer` collects instruction composers, deduplicates accounts across all instructions, calculates the message header, and produces a ready-to-sign transaction.

## Basic usage

```ruby
composer = Solace::TransactionComposer.new(connection: connection)

composer.add_instruction(
  Solace::Composers::SystemProgramTransferComposer.new(
    from: payer.address,
    to: recipient.address,
    lamports: 100_000_000
  )
)

composer.set_fee_payer(payer.address)

tx = composer.compose_transaction
tx.sign(payer)
```

## Multi-instruction transactions

Add multiple instruction composers to build complex transactions:

```ruby
composer = Solace::TransactionComposer.new(connection: connection)

# Transfer SOL
composer.add_instruction(
  Solace::Composers::SystemProgramTransferComposer.new(
    from: payer.address,
    to: recipient.address,
    lamports: 100_000_000
  )
)

# Transfer tokens
composer.add_instruction(
  Solace::Composers::SplTokenProgramTransferCheckedComposer.new(
    from: source_token_account,
    to: dest_token_account,
    mint: mint_address,
    authority: payer.address,
    amount: 1_000_000,
    decimals: 6
  )
)

composer.set_fee_payer(payer.address)

tx = composer.compose_transaction
tx.sign(payer)
```

The composer handles account deduplication — if `payer.address` appears in multiple instructions, it only shows up once in the final accounts array.

## Built-in composers

### System Program

- `SystemProgramTransferComposer` — SOL transfer
- `SystemProgramCreateAccountComposer` — create a new account

### SPL Token Program

- `SplTokenProgramTransferComposer` — token transfer
- `SplTokenProgramTransferCheckedComposer` — token transfer with decimal validation
- `SplTokenProgramMintToComposer` — mint tokens
- `SplTokenProgramInitializeMintComposer` — create a token mint
- `SplTokenProgramCloseAccountComposer` — close a token account

### Associated Token Account Program

- `AssociatedTokenAccountProgramCreateAccountComposer` — create an ATA
- `AssociatedTokenAccountProgramCreateIdempotentAccountComposer` — create an ATA (no-op if it exists)

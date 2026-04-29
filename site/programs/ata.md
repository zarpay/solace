# Associated Token Account Program

`Solace::Programs::AssociatedTokenAccount` provides methods for creating and managing Associated Token Accounts (ATAs).

An ATA is the canonical token account for a given wallet + mint pair. Most SPL Token operations in real-world applications use ATAs rather than raw token accounts.

## Setup

```ruby
connection = Solace::Connection.new('https://api.devnet.solana.com')
ata_program = Solace::Programs::AssociatedTokenAccount.new(connection: connection)
```

## Deriving an ATA address

The ATA address is a Program Derived Address (PDA) derived from the wallet, mint, and the ATA program ID:

```ruby
ata_address, _bump = Solace::Utils::PDA.find_program_address(
  [wallet_address, Solace::Constants::TOKEN_PROGRAM_ID, mint_address],
  Solace::Constants::ASSOCIATED_TOKEN_ACCOUNT_PROGRAM_ID
)
```

## Creating an ATA

Use the composer for creating ATAs within multi-instruction transactions:

```ruby
composer = Solace::TransactionComposer.new(connection: connection)

composer.add_instruction(
  Solace::Composers::AssociatedTokenAccountProgramCreateAccountComposer.new(
    payer: payer.address,
    wallet: recipient.address,
    mint: mint_address
  )
)

composer.set_fee_payer(payer.address)

tx = composer.compose_transaction
tx.sign(payer)
```

## Idempotent creation

Use the idempotent variant to safely create an ATA that may already exist — it becomes a no-op if the account is already initialized:

```ruby
composer.add_instruction(
  Solace::Composers::AssociatedTokenAccountProgramCreateIdempotentAccountComposer.new(
    payer: payer.address,
    wallet: recipient.address,
    mint: mint_address
  )
)
```

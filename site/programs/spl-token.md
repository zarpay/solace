# SPL Token Program

`Solace::Programs::SplToken` provides high-level methods for common SPL Token operations. Each method handles transaction assembly, signing, and submission.

## Setup

```ruby
connection = Solace::Connection.new('https://api.devnet.solana.com')
spl_token = Solace::Programs::SplToken.new(connection: connection)
```

## Create a token mint

```ruby
mint_keypair = Solace::Keypair.generate

response = spl_token.create_mint(
  payer: payer_keypair,
  decimals: 6,
  mint_authority: authority_keypair,
  freeze_authority: freeze_keypair,  # optional
  mint_keypair: mint_keypair         # optional, generates if not provided
)

connection.wait_for_confirmed_signature { response['result'] }
puts "Mint: #{mint_keypair.address}"
```

## Mint tokens

```ruby
response = spl_token.mint_to(
  payer: payer_keypair,
  mint: mint_keypair,
  destination: token_account_address,
  amount: 1_000_000,
  mint_authority: authority_keypair
)

connection.wait_for_confirmed_signature { response['result'] }
```

## Transfer tokens

```ruby
response = spl_token.transfer(
  payer: payer_keypair,
  source: source_token_account,
  destination: dest_token_account,
  amount: 500_000,
  owner: owner_keypair
)

connection.wait_for_confirmed_signature { response['result'] }
```

## Prepare methods

For more control, use prepare methods that return signed transactions without sending them:

```ruby
transaction = spl_token.compose_create_mint(
  payer: payer_keypair,
  decimals: 6,
  mint_authority: authority_keypair,
  freeze_authority: nil,
  mint_keypair: mint_keypair
)

# Inspect or modify before sending
signature = connection.send_transaction(transaction.serialize)
```

## When to use programs vs. composers

Programs are the fastest path for one-off operations. If you need to combine multiple instructions into a single transaction — for example, creating an ATA and transferring tokens atomically — use [Composers](/composers/overview) instead.

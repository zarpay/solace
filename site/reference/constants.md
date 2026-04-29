# Constants

`Solace::Constants` defines well-known Solana program IDs.

## Program IDs

```ruby
Solace::Constants::SYSTEM_PROGRAM_ID
# '11111111111111111111111111111111'

Solace::Constants::TOKEN_PROGRAM_ID
# 'TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA'

Solace::Constants::ASSOCIATED_TOKEN_ACCOUNT_PROGRAM_ID
# 'ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL'

Solace::Constants::SYSVAR_RENT_PROGRAM_ID
# 'SysvarRent111111111111111111111111111111111'

Solace::Constants::MEMO_PROGRAM_ID
# 'MemoSq4gqABAXKb96qnH8TysNcWxMyWCqXgDLGmfcHr'
```

## Usage

Constants are typically passed to instruction builders or composers:

```ruby
# In a manual instruction
account_context.add_readonly_nonsigner(Solace::Constants::TOKEN_PROGRAM_ID)

# In a composer
Solace::Composers::SplTokenProgramTransferComposer.new(
  from: source,
  to: dest,
  authority: owner,
  amount: 1_000_000
)
# The composer adds TOKEN_PROGRAM_ID automatically
```

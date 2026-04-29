# Keypairs

A `Solace::Keypair` wraps an Ed25519 signing key and its corresponding public key. It is the primary identity primitive — you use it to sign transactions and derive addresses.

## Generating a keypair

```ruby
keypair = Solace::Keypair.generate
puts keypair.address  # Base58-encoded public key
```

## Loading from bytes

If you have a raw 64-byte secret key (the format Solana CLI uses):

```ruby
keypair = Solace::Keypair.new(secret_key_bytes)
```

## PublicKey

`Solace::PublicKey` represents a 32-byte public key. You typically get one from a keypair, but you can also construct one from a Base58 string:

```ruby
pubkey = Solace::PublicKey.new('So11111111111111111111111111111111111111112')
puts pubkey.to_bytes  # 32-byte array
```

## Signing

Keypairs are passed to `Transaction#sign`:

```ruby
transaction = Solace::Transaction.new(message: message)
transaction.sign(keypair)
```

Multiple signers are supported:

```ruby
transaction.sign(payer, mint_authority)
```

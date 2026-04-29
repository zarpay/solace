# Connections

`Solace::Connection` is the RPC client. It wraps Solana's JSON-RPC API over HTTP.

## Creating a connection

```ruby
# Devnet
connection = Solace::Connection.new('https://api.devnet.solana.com')

# Mainnet
connection = Solace::Connection.new('https://api.mainnet-beta.solana.com')

# Custom RPC
connection = Solace::Connection.new('https://my-rpc.example.com')
```

## Common operations

### Get balance

```ruby
balance = connection.get_balance(keypair.address)
puts "#{balance} lamports"
```

### Get latest blockhash

```ruby
blockhash = connection.get_latest_blockhash
```

### Request airdrop (devnet/testnet only)

```ruby
response = connection.request_airdrop(keypair.address, 1_000_000_000)
connection.wait_for_confirmed_signature('finalized') { response['result'] }
```

### Send transaction

```ruby
response = connection.send_transaction(transaction.serialize)
signature = response['result']
```

### Wait for confirmation

```ruby
connection.wait_for_confirmed_signature('finalized') { signature }
```

The block form re-evaluates the signature expression on each poll. Pass a commitment level (`'processed'`, `'confirmed'`, or `'finalized'`) to control how many confirmations to wait for.

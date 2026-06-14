---
title: Tokens
---

# Tokens

`Solace::Tokens` is a small registry for token metadata — load a YAML list of tokens for a
network, then look them up by symbol or filter by attribute. It's a convenience for apps
that work with a known set of tokens (mints, decimals, names) rather than discovering them
on chain.

## Loading

```ruby
Solace::Tokens.load(path: 'tokens.yml', network: :mainnet)
```

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `path` | String | yes | Path to the YAML file. |
| `network` | String / Symbol | yes | The network key to load from the file. |

```yaml
# tokens.yml
mainnet:
  USDC:
    mint: "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v"
    decimals: 6
  PYUSD:
    mint: "2b1kV6DkPAnxd5ixfnxCpjxmKwqjjaYmCZfHsFu24GXo"
    decimals: 6
```

## Looking up

| Method | Returns | Description |
| --- | --- | --- |
| `all` | `Array<Token>` | Every loaded token. |
| `fetch(symbol)` | `Token \| nil` | The token for a symbol, or `nil`. |
| `where(criteria = {})` | `Array<Token>` | Tokens matching all the given attribute criteria. |
| `clear!` | — | Empty the registry. |

```ruby
usdc = Solace::Tokens.fetch('USDC')
usdc.mint     # => "EPjF…"
usdc.decimals # => 6

six_decimals = Solace::Tokens.where(decimals: 6)
```

## The Token object

`Solace::Tokens::Token` wraps a symbol and a metadata hash. Beyond `symbol` and `metadata`,
any metadata key is readable as a method (via `method_missing`), so the shape of your YAML
defines the accessors:

```ruby
token = Solace::Tokens::Token.new('USDC', mint: 'EPjF…', decimals: 6)
token.symbol   # => "USDC"
token.mint     # => "EPjF…"  (delegated to metadata)
token.decimals # => 6
```

`respond_to?` reflects the metadata keys too, so the dynamic accessors behave like real
methods.

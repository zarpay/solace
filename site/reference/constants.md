---
title: Constants
---

# Constants

`Solace::Constants` holds the well-known Solana program IDs, and can load additional
constants (e.g. your own program IDs or token addresses) from YAML.

## Program IDs

| Constant | Value |
| --- | --- |
| `SYSTEM_PROGRAM_ID` | `11111111111111111111111111111111` |
| `TOKEN_PROGRAM_ID` | `TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA` |
| `TOKEN_2022_PROGRAM_ID` | `TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb` |
| `ASSOCIATED_TOKEN_ACCOUNT_PROGRAM_ID` | `ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL` |
| `SYSVAR_RENT_PROGRAM_ID` | `SysvarRent111111111111111111111111111111111` |
| `COMPUTE_BUDGET_PROGRAM_ID` | `ComputeBudget111111111111111111111111111111` |
| `MEMO_PROGRAM_ID` | `MemoSq4gqABAXKb96qnH8TysNcWxMyWCqXgDLGmfcHr` |
| `ADDRESS_LOOKUP_TABLE_PROGRAM_ID` | `AddressLookupTab1e1111111111111111111111111` |

```ruby
Solace::Constants::SYSTEM_PROGRAM_ID
Solace::Constants::TOKEN_2022_PROGRAM_ID
```

These are the same across all clusters and are referenced throughout the
[instruction builders](/building/instruction-builders) and
[composers](/building/composers).

## Loading constants from YAML

`Solace::Constants.load` defines additional constants from a YAML file, namespaced so you
can keep per-cluster sets in one file.

| Parameter | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `path` | String | yes | — | Path to the YAML file. |
| `namespace` | String | no | `'default'` | Top-level key to load from. |
| `protect_overrides` | Boolean | no | `true` | Raise `ArgumentError` if a constant is already defined (rather than redefining it). |

```yaml
# constants.yml
mainnet:
  my_program_id: "Prog1111111111111111111111111111111111111111"
```

```ruby
Solace::Constants.load(path: 'constants.yml', namespace: 'mainnet')
Solace::Constants::MY_PROGRAM_ID # => "Prog1111…"
```

Keys are upper-cased to form the constant name. With `protect_overrides: false`, an existing
constant is removed and redefined instead of raising.

# Messages

A `Solace::Message` is the inner payload of a transaction. It contains the accounts array, instructions, blockhash, and header metadata.

## Structure

```ruby
message = Solace::Message.new(
  header: [
    1, # required_signatures
    0, # readonly_signed
    1  # readonly_unsigned
  ],
  accounts: [
    payer.address,
    recipient.address,
    Solace::Constants::SYSTEM_PROGRAM_ID
  ],
  instructions: [transfer_instruction],
  recent_blockhash: connection.get_latest_blockhash
)
```

### Header

The header is a 3-element array:

| Index | Meaning |
| --- | --- |
| 0 | Number of required signatures |
| 1 | Number of read-only signed accounts |
| 2 | Number of read-only unsigned accounts |

### Accounts

The accounts array lists every account referenced by any instruction in the transaction. Order matters — instruction data references accounts by their index in this array.

### Instructions

An array of `Solace::Instruction` objects. Each instruction references accounts by index into the message's accounts array.

## When to use directly

If you're using [Composers](/composers/overview), you won't construct messages by hand — the `TransactionComposer` builds the message for you. Direct message construction is useful when you need precise control over account ordering or are working with custom programs.

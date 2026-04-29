# Custom Composers

Extend `Solace::Composers::Base` to build instruction composers for your own Solana programs.

## Implementing a composer

A composer needs two methods:

1. **`setup_accounts`** — declare which accounts the instruction uses and their access permissions
2. **`build_instruction(context)`** — build the `Instruction` using resolved account indices

```ruby
class MyProgramComposer < Solace::Composers::Base
  def setup_accounts
    account_context.add_writable_signer(params[:from])
    account_context.add_writable_nonsigner(params[:to])
    account_context.add_readonly_nonsigner(params[:program])
  end

  def build_instruction(context)
    Solace::Instructions::MyProgram::MyInstruction.build(
      data: params[:data],
      from_index: context.index_of(params[:from]),
      to_index: context.index_of(params[:to]),
      program_index: context.index_of(params[:program])
    )
  end
end
```

## How it works

### Constructor

All keyword arguments passed to `new` are available in the `params` hash:

```ruby
composer = MyProgramComposer.new(from: 'abc...', to: 'def...', program: '111...')
composer.params[:from]  # => 'abc...'
```

### Account context

The `account_context` tracks accounts and their access levels. Use these methods to register accounts:

| Method | Access |
| --- | --- |
| `add_writable_signer(address)` | Read/write, must sign |
| `add_readonly_signer(address)` | Read-only, must sign |
| `add_writable_nonsigner(address)` | Read/write, no signature |
| `add_readonly_nonsigner(address)` | Read-only, no signature |

### Build context

The `context` passed to `build_instruction` provides `index_of(address)` — it returns the account's final index in the composed transaction's accounts array. This lets you reference accounts without knowing their position ahead of time.

## Using your composer

```ruby
composer = Solace::TransactionComposer.new(connection: connection)

composer.add_instruction(
  MyProgramComposer.new(
    from: payer.address,
    to: recipient.address,
    program: MY_PROGRAM_ID,
    data: [1, 2, 3]
  )
)

composer.set_fee_payer(payer.address)

tx = composer.compose_transaction
tx.sign(payer)
```

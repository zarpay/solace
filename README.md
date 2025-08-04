# Solace Ruby SDK Documentation
A Ruby SDK for the Solana blockchain.

## Overview

Solace is a comprehensive Ruby SDK for interacting with the Solana blockchain. It provides both low-level building blocks and high-level abstractions for composing, signing, and sending Solana transactions. The library aims to follow Ruby conventions while maintaining compatibility with Solana's binary protocols.

## Architecture

The Solace SDK is organized into several key layers:

### 1. **Core Classes** (Low-Level)
- **Keypair/PublicKey**: Ed25519 cryptographic operations
- **Connection**: RPC client for Solana nodes
- **Transaction/Message/Instruction/AddressLookupTable**: Transaction building blocks
- **Serializers**: Binary serialization/deserialization system

### 2. **Instruction Builders** (Low-Level)
- Service objects that build specific instruction types
- Handle binary data encoding and account indexing
- Located in `lib/solace/instructions/`

### 3. **Composers** (High-Level)
- Convenient interfaces for composing transactions and instructions
- Handle account ordering and header calculations for transactions
- Located in `lib/solace/composers`

### 3. **Programs** (High-Level)
- Convenient interfaces for interacting with on-chain programs
- Handle transaction assembly, signing, and submission
- Located in `lib/solace/programs/`

### 4. **Utilities** (Support modules & classes)
- **Codecs**: Base58/Base64 encoding, compact integers, little-endian encoding
- **PDA**: Program Derived Address generation
- **Curve25519**: Native curve operations via FFI
- **More...**: Checkout `lib/solace/utils` 

## Core Components

### Transaction & Message

Transactions contain a message and signatures. Messages contain instructions and metadata. This core class is as simple as possible and provide the lowest level of abstraction for building and sending transactions. A developer is expected to:

1. Manually fill and order the accounts array
2. Manually fill and order the instructions array
3. Manually calculate the header
4. ...did I forget to say manually?

```ruby
# Create a message
message = Solace::Message.new(
    header: [
        1, # required_signatures
        0, # readonly_signed
        1  # readonly_unsigned
    ],
    accounts: [
        payer.address,
        recipient.address,
        system_program_id
    ],
    instructions: [transfer_instruction],
    recent_blockhash: connection.get_latest_blockhash,
)

# Create and sign transaction
transaction = Solace::Transaction.new(message: message)
transaction.sign(payer_keypair)

# Send transaction
signature = connection.send_transaction(transaction.serialize)
```

**Key Features:**
- Legacy and versioned transaction support
- Automatic signature management
- Binary serialization/deserialization
- Address lookup table support (versioned)

### Instruction

Instructions represent individual operations within a transaction. Like messages, instructions are as simple as possible and provide the lowest level of abstraction for building and sending transactions. A developer is expected to:

1. Manually fill and order the accounts indices array
2. Manually specify the program index
3. Manually specify the data

```ruby
instruction = Solace::Instruction.new(
    program_index: 2,  # Index in accounts array
    accounts: [0, 1],  # Account indices
    data: [2, 0, 0, 0] + amount_bytes  # Instruction data
)

# All instructions have accessor methods for program_index, accounts, and data
instruction.program_index # => 2
instruction.accounts # => [0, 1]
instruction.data # => [2, 0, 0, 0] + amount_bytes
```

**Key Features:**
- Program index referencing
- Account index arrays
- Binary data payload
- Serializable format

## Low-Level Instruction Builders

Given that the low-level instruction class is fully available, it's easy to build higher-level instruction builders that wrap the low-level instruction class. These builders are service objects that create specific instruction types. They handle the binary encoding required by Solana programs.

For example, the SystemProgram::TransferInstruction builder is a service object that creates and returns a Solace::Instruction object with the correct program index, accounts indices, and data for a System Program solana transfer.

```ruby
# Build a SOL transfer instruction
transfer_ix = Solace::Instructions::SystemProgram::TransferInstruction.build(
  lamports: 1_000_000,  # 0.001 SOL
  from_index: 0,        # Sender account index
  to_index: 1,          # Recipient account index
  program_index: 2      # System program index
)
```

Solace includes a number of these, and you can build your own as well.

- `Solace::Instructions::SystemProgram::TransferInstruction`
- `Solace::Instructions::SystemProgram::CreateAccountInstruction`
- `Solace::Instructions::SplToken::InitializeMintInstruction`
- `Solace::Instructions::SplToken::InitializeAccountInstruction`
- `Solace::Instructions::SplToken::MintToInstruction`
- `Solace::Instructions::SplToken::TransferInstruction`
- `Solace::Instructions::SplToken::TransferCheckedInstruction`
- `Solace::Instructions::AssociatedTokenAccount::CreateAssociatedTokenAccountInstruction`

**Common Patterns:**
- All builders use `.build()` class method
- All builders use `.data()` method to specify the instruction data
- All builders use named parameters and `_index` suffix for account indices
- All builders use a `program_index` parameter to specify the program index
- Account indices reference the transaction's accounts array
- Binary data encoding handled automatically
- Instruction-specific data layouts documented in comments

## High-Level Program Classes

**WARNING: Programs will probably get deprecated in favor of composers in the future.**

Now that we have the mid-level instruction builders, we can create high-level program classes that provide convenient interfaces for common operations, handling transaction assembly, signing, and submission.

For example, the `Solace::Programs::SplToken` class provides a high-level interface for interacting with the SPL Token Program.

### SPL Token Program

```ruby
# Initialize program client
spl_token = Solace::Programs::SplToken.new(connection: connection)

# Create a new token mint
response = spl_token.create_mint(
  payer: payer_keypair,
  decimals: 6,
  mint_authority: authority_keypair,
  freeze_authority: freeze_keypair,  # Optional
  mint_keypair: mint_keypair         # Optional, generates if not provided
)
connection.wait_for_confirmed_signature { response['result'] }

# Mint tokens to an account
response = spl_token.mint_to(
  payer: payer_keypair,
  mint: mint_keypair,
  destination: token_account_address,
  amount: 1_000_000,
  mint_authority: authority_keypair
)
connection.wait_for_confirmed_signature { response['result'] }

# Transfer tokens
response = spl_token.transfer(
  payer: payer_keypair,
  source: source_token_account,
  destination: dest_token_account,
  amount: 500_000,
  owner: owner_keypair
)
connection.wait_for_confirmed_signature { response['result'] }
```

**Key Features:**
- Automatic transaction assembly
- Built-in signing and submission
- Error handling and validation
- Sensible defaults for common operations
- Returns transaction signatures

### Prepare Methods

For more control, use "prepare" methods that return signed transactions without sending it on the program:

```ruby
# Prepare transaction without sending
transaction = spl_token.prepare_create_mint(
  payer: payer_keypair,
  decimals: 6,
  mint_authority: authority_keypair,
  freeze_authority: nil,
  mint_keypair: mint_keypair
)

# Inspect or modify transaction before sending
puts transaction.serialize  # Base64 transaction
signature = connection.send_transaction(transaction.serialize)
```

## Utility Modules

### Codecs

The `Solace::Utils::Codecs` module provides encoding/decoding utilities for Solana data types.

```ruby
# Base58 operations
base58_string = Solace::Utils::Codecs.bytes_to_base58(bytes)
bytes = Solace::Utils::Codecs.base58_to_bytes(base58_string)

# Compact u16 encoding (ShortVec)
encoded = Solace::Utils::Codecs.encode_compact_u16(1234)
value, bytes_read = Solace::Utils::Codecs.decode_compact_u16(io)

# Little-endian u64
encoded = Solace::Utils::Codecs.encode_le_u64(amount)
value = Solace::Utils::Codecs.decode_le_u64(io)

# Base64 to IO stream
io = Solace::Utils::Codecs.base64_to_bytestream(base64_string)
```

### Program Derived Addresses (PDA)

```ruby
# Find PDA with bump seed
seeds = ['metadata', mint_address, 'edition']
program_id = 'metaqbxxUerdq28cj1RbAWkYQm3ybzjb6a8bt518x1s'

address, bump = Solace::Utils::PDA.find_program_address(seeds, program_id)
```

**Key Features:**
- Automatic bump seed finding
- Multiple seed type support (String, Integer, Array)
- Base58 address detection
- SHA256 hashing with curve validation

### Curve25519 Operations

```ruby
# Check if point is on curve (used in PDA validation)
on_curve = Solace::Utils::Curve25519Dalek.on_curve?(32_byte_point)
```

## Constants

**WARNING: Constants will probably get deprecated in favor of config file that developers can use to define their own constants with required values.**

Common Solana program IDs are defined in `Solace::Constants`:

```ruby
Solace::Constants::SYSTEM_PROGRAM_ID                    # '11111111111111111111111111111111'
Solace::Constants::TOKEN_PROGRAM_ID                     # 'TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA'
Solace::Constants::ASSOCIATED_TOKEN_ACCOUNT_PROGRAM_ID  # 'ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL'
Solace::Constants::SYSVAR_RENT_PROGRAM_ID               # 'SysvarRent111111111111111111111111111111111'
Solace::Constants::MEMO_PROGRAM_ID                      # 'MemoSq4gqABAXKb96qnH8TysNcWxMyWCqXgDLGmfcHr'
```

## Composers

Composers are used to build transactions from multiple instructions. They handle all the low-level details of transaction assembly, such as account ordering, header calculation, and fee payer selection.

```ruby
# Initialize a transaction composer
composer = Solace::TransactionComposer.new(connection: connection)

# Add an instruction composer
composer.add_instruction(
  Solace::Composers::SystemProgramTransferComposer.new(
    to: 'pubkey1',
    from: 'pubkey2',
    lamports: 100
  )
)

# Add another instruction composer
composer.add_instruction(
  Solace::Composers::SplTokenProgramTransferCheckedComposer.new(
    from: 'pubkey4',
    to: 'pubkey5',
    mint: 'pubkey6',
    authority: 'pubkey7',
    amount: 1_000_000,
    decimals: 6
  )
)

# Set the fee payer
composer.set_fee_payer('pubkey8')

# Compose the transaction
tx = composer.compose_transaction

# Sign the transaction with all required signers
tx.sign(*any_required_signers)
```

Composers are intended to be extended by developers with custom instruction composers to interface with their own programs. Simply inherit from `Solace::Composers::Base` and implement the required methods.

```ruby
class MyProgramComposer < Solace::Composers::Base
  # All keyword arguments are passed to the constructor and available
  # as a `params` hash.
  # 
  # The setup_accounts method is called automatically by the transaction composer
  # during compilation and should be used to add accounts to the account_context 
  # with the appropriate access permissions. Conditional logic is fine here given 
  # and available params to determine the access permissions.
  def setup_accounts
    account_context.add_writable_signer(params[:from])
    account_context.add_writable_nonsigner(params[:to])
    account_context.add_readonly_nonsigner(params[:program])
  end

  # The build_instruction method is called automatically by the transaction composer
  # during compilation and should be used to build the instruction using an instruction builder.
  # 
  # The passed context to the build_instruction method provides the indices of all accounts
  # that were added to the account_context in the setup_accounts method. These are accessible
  # by the index_of method of the context using the account address as a parameter.
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

## Practical Examples

### Complete SOL Transfer

```ruby
require 'solace'

# Setup
payer = Solace::Keypair.generate
recipient = Solace::Keypair.generate

# Create connection
connection = Solace::Connection.new('https://api.devnet.solana.com')

# Fund payer (devnet only)
response = connection.request_airdrop(payer.address, 1_000_000_000)
connection.wait_for_confirmed_signature('finalized') { response['result'] }

# Build transfer instruction
transfer_ix = Solace::Instructions::SystemProgram::TransferInstruction.build(
  lamports: 100_000_000,  # 0.1 SOL
  from_index: 0,
  to_index: 1,
  program_index: 2
)

# Create message
message = Solace::Message.new(
  accounts: [
    payer.address,
    recipient.address,
    Solace::Constants::SYSTEM_PROGRAM_ID
  ],
  instructions: [transfer_ix],
  recent_blockhash: connection.get_latest_blockhash,
  header: [1, 0, 1]
)

# Sign and send
transaction = Solace::Transaction.new(message: message)
transaction.sign(payer)

response = connection.send_transaction(transaction.serialize)
puts "Transaction: #{response['result']}"
```

### Complete Token Mint Creation

```ruby
require 'solace'

# Setup
payer = Solace::Keypair.generate
mint_keypair = Solace::Keypair.generate

# Create connection
connection = Solace::Connection.new('https://api.devnet.solana.com')

# Fund payer
response = connection.request_airdrop(payer.address, 1_000_000_000)
connection.wait_for_confirmed_signature('finalized') { response['result'] }

# High-level approach
program = Solace::Programs::SplToken.new(connection: connection)
signature = program.create_mint(
  payer: payer,
  decimals: 6,
  mint_authority: payer,
  freeze_authority: nil,
  mint_keypair: mint_keypair
)

puts "Mint created: #{mint_keypair.address}"
puts "Transaction: #{signature}"
```

## Design Patterns

### Service Objects
Instruction builders follow the service object pattern:
- Single responsibility (build one instruction type)
- Class methods for stateless operations
- Consistent `.build()` interface
- Separate `.data()` methods for instruction data

## Testing Support

The SDK includes comprehensive test utilities:

```ruby
# Test fixtures for keypairs
bob = Fixtures.load_keypair('bob')
alice = Fixtures.load_keypair('anna')

# Automatic funding in test environment
response = connection.request_airdrop(keypair.address, 10_000_000_000)
connection.wait_for_confirmed_signature { response['result'] }

# Transaction confirmation helpers
response = connection.send_transaction(transaction.serialize)
connection.wait_for_confirmed_signature { response['result'] }
```

## Dependencies

- **base58**: Base58 encoding/decoding
- **base64**: Base64 encoding/decoding
- **rbnacl**: Ed25519 cryptography
- **ffi**: Foreign Function Interface for native libraries
- **json**: JSON parsing for RPC
- **net/http**: HTTP client for RPC calls

## Current Limitations

### High-Impact/Foundational Next Steps

1. **Associated Token Account Program**
   - Implement: close_associated_token_account, and helpers for derivation.
   - Rationale: Required for user wallets and token UX. **Most SPL Token operations depend on ATAs to be useful in real-world workflows.**

2. **Full SPL Token Program Coverage** _(depends on ATA support)_
   - Implement: mint_to, burn, close_account, set_authority, freeze/thaw, approve/revoke, etc.
   - Rationale: Most dApps and DeFi protocols rely on SPL tokens. **For practical use, SPL Token instructions should leverage ATA helpers.**

3. **Account Data Parsing**
   - Implement: Decoders for token accounts, mint accounts, stake accounts, etc.
   - Rationale: Needed to read on-chain state.

4. **Transaction Simulation**
   - Implement: `simulateTransaction` RPC endpoint.
   - Rationale: Allows dry-run and error debugging.

5. **Error Decoding**
   - Implement: Map program error codes to readable errors.
   - Rationale: Improves DX and debugging.

---

### Medium-Impact

6. **Address Lookup Table Support**
   - Implement: Create, extend, use ALT in transactions.
   - Rationale: Needed for scalable DeFi/protocols.

7. **Stake Program**
   - Implement: delegate, deactivate, withdraw, split, merge.
   - Rationale: For validators, staking dApps.

8. **Websocket/Event Subscription**
   - Implement: Account/slot/transaction subscriptions.
   - Rationale: For real-time apps and bots.

9. **Utility Functions**
   - base58/base64 encode/decode, lamports/SOL conversions, etc.

10. **Advanced Transaction Features**
    - Durable nonce, versioned transactions, partial signing.

---

### Low-Impact/Advanced

- Governance program
- Anchor IDL/Anchor-style program support
- Program deployment (BPF loader)

## Conclusion

Solace provides a comprehensive, Ruby-idiomatic interface to the Solana blockchain. Its layered architecture allows developers to choose the appropriate level of abstraction for their needs, from low-level instruction building to high-level program interactions. The consistent patterns and thorough documentation make it accessible to Ruby developers while maintaining the power and flexibility needed for complex Solana applications.

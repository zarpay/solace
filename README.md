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

Transactions contain a message and signatures. Messages contain instructions and metadata.

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

Instructions represent individual operations within a transaction.

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

Instruction builders are service objects that create specific instruction types. They handle the binary encoding required by Solana programs.

### System Program Instructions

#### Transfer Instruction

```ruby
# Build a SOL transfer instruction
transfer_ix = Solace::Instructions::SystemProgram::TransferInstruction.build(
  lamports: 1_000_000,  # 0.001 SOL
  from_index: 0,        # Sender account index
  to_index: 1,          # Recipient account index
  program_index: 2      # System program index
)
```

#### Create Account Instruction

```ruby
# Build account creation instruction
create_ix = Solace::Instructions::SystemProgram::CreateAccountInstruction.build(
  from_index: 0,              # Payer account index
  new_account_index: 1,       # New account index
  system_program_index: 2,    # System program index
  lamports: rent_lamports,    # Rent-exempt amount
  space: 165,                 # Account data size
  owner: token_program_id     # Owning program
)
```

### SPL Token Instructions

#### Initialize Mint Instruction

```ruby
# Initialize a new token mint
init_mint_ix = Solace::Instructions::SplToken::InitializeMintInstruction.build(
  mint_account_index: 1,      # Mint account index
  rent_sysvar_index: 2,       # Rent sysvar index
  program_index: 3,           # Token program index
  decimals: 6,                # Token decimals
  mint_authority: authority_pubkey,
  freeze_authority: freeze_pubkey  # Optional
)
```

#### Mint To Instruction

```ruby
# Mint tokens to an account
mint_to_ix = Solace::Instructions::SplToken::MintToInstruction.build(
  amount: 1_000_000,          # Amount to mint
  mint_index: 0,              # Mint account index
  destination_index: 1,       # Destination token account
  mint_authority_index: 2,    # Mint authority index
  program_index: 3            # Token program index
)
```

#### Transfer Instruction

```ruby
# Transfer tokens between accounts
transfer_ix = Solace::Instructions::SplToken::TransferInstruction.build(
  amount: 500_000,            # Amount to transfer
  source_index: 0,            # Source token account
  destination_index: 1,       # Destination token account
  owner_index: 2,             # Owner/authority index
  program_index: 3            # Token program index
)
```

**Common Patterns:**
- All builders use `.build()` class method
- Account indices reference the transaction's accounts array
- Binary data encoding handled automatically
- Instruction-specific data layouts documented in comments

## High-Level Program Methods

Program clients provide convenient interfaces for common operations, handling transaction assembly, signing, and submission.

### SPL Token Program

```ruby
# Initialize program client
spl_token = Solace::Programs::SplToken.new(connection: connection)

# Create a new token mint
signature = spl_token.create_mint(
  payer: payer_keypair,
  decimals: 6,
  mint_authority: authority_keypair,
  freeze_authority: freeze_keypair,  # Optional
  mint_keypair: mint_keypair         # Optional, generates if not provided
)

# Mint tokens to an account
signature = spl_token.mint_to(
  payer: payer_keypair,
  mint: mint_keypair,
  destination: token_account_address,
  amount: 1_000_000,
  mint_authority: authority_keypair
)

# Transfer tokens
signature = spl_token.transfer(
  payer: payer_keypair,
  source: source_token_account,
  destination: dest_token_account,
  amount: 500_000,
  owner: owner_keypair
)
```

**Key Features:**
- Automatic transaction assembly
- Built-in signing and submission
- Error handling and validation
- Sensible defaults for common operations
- Returns transaction signatures

### Prepare Methods

For more control, use "prepare" methods that return signed transactions without sending:

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

## Serialization System

Solace uses a serialization system for converting Ruby objects to/from Solana's binary format.

### SerializableRecord Base Class

```ruby
class Transaction < Solace::SerializableRecord
  SERIALIZER = Solace::Serializers::TransactionSerializer
  DESERIALIZER = Solace::Serializers::TransactionDeserializer
  
  # Automatic serialization
  def serialize
    self.class::SERIALIZER.call(self)
  end
  
  # Automatic deserialization
  def self.deserialize(io)
    self::DESERIALIZER.call(io)
  end
end
```

### Serializer Pattern

```ruby
class TransactionSerializer < Solace::Serializers::Base
  STEPS = %i[
    serialize_signatures
    serialize_message
  ].freeze
  
  def serialize_signatures
    # Convert signatures to binary format
  end
  
  def serialize_message
    # Serialize message component
  end
end
```

**Key Features:**
- Step-based serialization process
- Automatic Base64 encoding
- Consistent error handling
- Reversible serialization/deserialization

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

# Create PDA directly
address = Solace::Utils::PDA.create_program_address(seeds + [bump], program_id)
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

Common Solana program IDs are defined in `Solace::Constants`:

```ruby
Solace::Constants::SYSTEM_PROGRAM_ID                    # '11111111111111111111111111111111'
Solace::Constants::TOKEN_PROGRAM_ID                     # 'TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA'
Solace::Constants::ASSOCIATED_TOKEN_ACCOUNT_PROGRAM_ID  # 'ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL'
Solace::Constants::SYSVAR_RENT_PROGRAM_ID               # 'SysvarRent111111111111111111111111111111111'
Solace::Constants::MEMO_PROGRAM_ID                      # 'MemoSq4gqABAXKb96qnH8TysNcWxMyWCqXgDLGmfcHr'
```

## Practical Examples

### Complete SOL Transfer

```ruby
require 'solace'

# Setup
connection = Solace::Connection.new('https://api.devnet.solana.com')
payer = Solace::Keypair.generate
recipient = Solace::Keypair.generate

# Fund payer (devnet only)
connection.request_airdrop(payer.address, 1_000_000_000)

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
signature = connection.send_transaction(transaction.serialize)

puts "Transaction: #{signature}"
```

### Complete Token Mint Creation

```ruby
require 'solace'

# Setup
connection = Solace::Connection.new('https://api.devnet.solana.com')
payer = Solace::Keypair.generate
mint_keypair = Solace::Keypair.generate

# Fund payer
connection.request_airdrop(payer.address, 1_000_000_000)

# High-level approach
spl_token = Solace::Programs::SplToken.new(connection: connection)
signature = spl_token.create_mint(
  payer: payer,
  decimals: 6,
  mint_authority: payer,
  freeze_authority: nil,
  mint_keypair: mint_keypair
)

puts "Mint created: #{mint_keypair.address}"
puts "Transaction: #{signature}"
```

### Manual Transaction Building

```ruby
# Low-level approach for maximum control
rent_lamports = connection.get_minimum_lamports_for_rent_exemption(82)

# Build instructions
create_account_ix = Solace::Instructions::SystemProgram::CreateAccountInstruction.build(
  from_index: 0,
  new_account_index: 1,
  system_program_index: 4,
  lamports: rent_lamports,
  space: 82,
  owner: Solace::Constants::TOKEN_PROGRAM_ID
)

initialize_mint_ix = Solace::Instructions::SplToken::InitializeMintInstruction.build(
  mint_account_index: 1,
  rent_sysvar_index: 2,
  program_index: 3,
  decimals: 6,
  mint_authority: payer.address
)

# Assemble transaction
message = Solace::Message.new(
  accounts: [
    payer.address,
    mint_keypair.address,
    Solace::Constants::SYSVAR_RENT_PROGRAM_ID,
    Solace::Constants::TOKEN_PROGRAM_ID,
    Solace::Constants::SYSTEM_PROGRAM_ID
  ],
  instructions: [create_account_ix, initialize_mint_ix],
  recent_blockhash: connection.get_latest_blockhash,
  header: [2, 0, 3]  # 2 signers, 0 readonly signed, 3 readonly unsigned
)

transaction = Solace::Transaction.new(message: message)
transaction.sign(payer, mint_keypair)
signature = connection.send_transaction(transaction.serialize)
```

## Design Patterns

### Service Objects
Instruction builders follow the service object pattern:
- Single responsibility (build one instruction type)
- Class methods for stateless operations
- Consistent `.build()` interface
- Separate `.data()` methods for instruction data

### Serializable Records
Core data structures inherit from `SerializableRecord`:
- Automatic serialization/deserialization
- Consistent binary format handling
- SERIALIZER/DESERIALIZER constants pattern

### Mixin Modules
Shared functionality via mixins:
- `BinarySerializable` for serialization support
- `PDA` for Program Derived Address operations
- `Utils` modules for common operations

### Builder Pattern
High-level program methods use builder pattern:
- Fluent interfaces with keyword arguments
- Sensible defaults for optional parameters
- Automatic transaction assembly and signing

## Error Handling

The SDK provides comprehensive error handling:

```ruby
begin
  signature = connection.send_transaction(transaction.serialize)
rescue StandardError => e
  puts "Transaction failed: #{e.message}"
end

# PDA validation
begin
  address = Solace::Utils::PDA.create_program_address(seeds, program_id)
rescue Solace::Utils::PDA::InvalidPDAError => e
  puts "Invalid PDA: #{e.message}"
end
```

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

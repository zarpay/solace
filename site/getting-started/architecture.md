# Architecture

Solace is organized into layers. Each layer builds on the one below it. Pick the level of abstraction that fits your use case.

## Layers

### 1. Core classes (low-level)

The fundamental building blocks. You assemble everything yourself — account arrays, instruction data, header bytes.

- **Keypair, PublicKey** — Ed25519 cryptographic operations
- **Connection** — RPC client for Solana nodes
- **Transaction, Message, Instruction** — transaction primitives
- **AddressLookupTable** — versioned transaction support

### 2. Instruction builders (low-level)

Service objects that create `Instruction` instances for specific Solana programs. They handle binary encoding so you don't have to, but you still manage account ordering and indices yourself.

Located in `lib/solace/instructions/`.

### 3. Composers (high-level) — recommended

The preferred way to build transactions. A `TransactionComposer` collects instruction composers, deduplicates accounts across all instructions, calculates the message header, and produces a signed transaction.

Located in `lib/solace/composers/`.

### 4. Programs (high-level)

Convenience wrappers that handle the full lifecycle — instruction assembly, signing, and RPC submission — in a single method call.

Located in `lib/solace/programs/`.

### 5. Utilities

Cross-cutting helpers: Base58/Base64 codecs, PDA derivation, curve25519 operations via FFI.

Located in `lib/solace/utils/`.

## Choosing a layer

| Need | Use |
| --- | --- |
| Maximum control over every byte | Core classes + instruction builders |
| Build multi-instruction transactions cleanly | Composers |
| One-liner for common operations (mint, transfer) | Programs |

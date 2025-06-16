# Solace Ruby SDK: Feature Coverage

## Core Features

| Feature                                   | Status         |
|-------------------------------------------|----------------|
| Keypair/PublicKey                         | ✅ Implemented |
| RPC Client (Connection)                   | ✅ Implemented |
| Transaction Construction/Signing          | ✅ Implemented |
| System Program (transfer, create account) | ✅ Implemented |
| Token Program (partial)                   | 🚧 Partial     |
| Associated Token Account                  | ❌ Not Yet     |
| Account Data Parsing                      | 🚧 Partial     |
| Transaction Simulation                    | ❌ Not Yet     |
| Error Decoding                            | 🚧 Partial     |
| Stake Program                             | ❌ Not Yet     |
| Address Lookup Tables                     | ❌ Not Yet     |
| Websocket/Event Subscription              | ❌ Not Yet     |
| Utility Functions                         | 🚧 Partial     |
| Program Deployment                        | ❌ Not Yet     |
| Governance Program                        | ❌ Not Yet     |
| Anchor/IDL Support                        | ❌ Not Yet     |


## Roadmap & Priorities

### High-Impact/Foundational Next Steps

1. **Associated Token Account Program**
   - Implement: create_associated_token_account, close_associated_token_account, and helpers for derivation.
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


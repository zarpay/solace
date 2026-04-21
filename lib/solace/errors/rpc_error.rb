# frozen_string_literal: true

module Solace
  module Errors
    # Raised when the RPC node returns an error response.
    #
    # This error is raised when the Solana RPC node successfully processes the HTTP
    # request but returns an error in the JSON-RPC response. This includes errors
    # like invalid parameters, insufficient funds, blockhash not found, and other
    # RPC method-specific errors. The error message and code from the RPC response
    # are included in the exception.
    #
    # @example Handling RPC errors
    #   begin
    #     connection.send_transaction(transaction)
    #   rescue Solace::Errors::RPCError => e
    #     puts "RPC error (code #{e.code}): #{e.message}"
    #   end
    #
    # @see Solace::Errors::HTTPError
    # @since 0.0.1
    class RPCError < ConnectionError
      attr_reader :rpc_code, :rpc_message, :rpc_data

      # @param [String] message The error message
      # @param [Integer] rpc_code The JSON-RPC error code
      # @param [String] rpc_message The JSON-RPC error message
      # @param [Object] rpc_data The JSON-RPC error data
      def initialize(message, rpc_code:, rpc_message:, rpc_data: nil)
        super(message)
        @rpc_code = rpc_code
        @rpc_message = rpc_message
        @rpc_data = rpc_data
      end

      # Maps JSON-RPC / Solana error codes to specific error subclasses.
      # Codes not in this map will raise a generic {RPCError}.
      # Source: anza-xyz/kit (packages/errors/src/codes.ts)
      #         anza-xyz/agave (rpc-client-api/src/custom_error.rs)
      #
      # @return [Hash{Integer => Symbol}]
      CODE_MAP = {
        # ── Standard JSON-RPC 2.0 errors ──────────────────────────────────
        -32_700 => :ServerParseError,                                    # Invalid JSON received by the server
        -32_603 => :InternalError,                                       # Internal JSON-RPC error
        -32_602 => :InvalidParamsError,                                  # Invalid method parameters
        -32_601 => :MethodNotFoundError,                                 # Requested method does not exist
        -32_600 => :InvalidRequestError,                                 # JSON sent is not a valid request

        # ── Solana RPC server errors (from anza-xyz/kit + agave) ──────────
        -32_001 => :BlockCleanedUpError,                                 # Block cleaned up, does not exist on node
        -32_002 => :SendTransactionPreflightFailureError,                # Transaction preflight simulation failed
        -32_003 => :TransactionSignatureVerificationFailureError,        # Transaction signature verification failure
        -32_004 => :BlockNotAvailableError,                              # Block not available for slot
        -32_005 => :NodeUnhealthyError,                                  # Node is behind or not fully synced
        -32_006 => :TransactionPrecompileVerificationFailureError,       # Transaction precompile verification failure
        -32_007 => :SlotSkippedError,                                    # Slot was skipped or missing due to ledger jump
        -32_008 => :NoSnapshotError,                                     # No snapshot available
        -32_009 => :LongTermStorageSlotSkippedError,                     # Slot skipped in long-term storage
        -32_010 => :KeyExcludedFromSecondaryIndexError,                  # Key excluded from secondary account index
        -32_011 => :TransactionHistoryNotAvailableError,                 # Transaction history not available from this node
        -32_012 => :ScanError,                                           # Scan operation encountered an error
        -32_013 => :TransactionSignatureLengthMismatchError,             # Transaction signature length mismatch
        -32_014 => :BlockStatusNotAvailableYetError,                     # Block status not yet available for slot
        -32_015 => :UnsupportedTransactionVersionError,                  # Transaction version unsupported by client
        -32_016 => :MinContextSlotNotReachedError,                       # Minimum context slot has not been reached
        -32_017 => :EpochRewardsPeriodActiveError,                       # Epoch rewards period still active at slot
        -32_018 => :SlotNotEpochBoundaryError,                           # Slot is not an epoch boundary
        -32_019 => :LongTermStorageUnreachableError,                     # Failed to query long-term storage
        -32_020 => :FilterTransactionNotFoundError,                      # Transaction not found (agave)

        # ── Core errors ───────────────────────────────────────────────────
        1       => :BlockHeightExceededError,                            # Block height exceeded
        2       => :InvalidNonceError,                                   # Invalid nonce
        3       => :NonceAccountNotFoundError,                           # Nonce account not found
        4       => :BlockhashStringLengthOutOfRangeError,                # Blockhash string length out of range
        5       => :InvalidBlockhashByteLengthError,                     # Invalid blockhash byte length
        6       => :LamportsOutOfRangeError,                             # Lamports out of range
        7       => :MalformedBigintStringError,                          # Malformed bigint string
        8       => :MalformedNumberStringError,                          # Malformed number string
        9       => :TimestampOutOfRangeError,                            # Timestamp out of range
        10      => :MalformedJsonRpcError,                               # Malformed JSON-RPC error response
        11      => :FailedToSendTransactionError,                        # Failed to send transaction
        12      => :FailedToSendTransactionsError,                       # Failed to send transactions

        # ── Address errors ────────────────────────────────────────────────
        2_800_000 => :AddressInvalidByteLengthError,                     # Invalid address byte length
        2_800_001 => :AddressStringLengthOutOfRangeError,                # Address string length out of range
        2_800_002 => :InvalidBase58EncodedAddressError,                  # Invalid base58-encoded address
        2_800_003 => :InvalidEd25519PublicKeyError,                      # Invalid Ed25519 public key
        2_800_004 => :MalformedPdaError,                                 # Malformed PDA
        2_800_005 => :PdaBumpSeedOutOfRangeError,                        # PDA bump seed out of range
        2_800_006 => :MaxNumberOfPdaSeedsExceededError,                  # Max number of PDA seeds exceeded
        2_800_007 => :MaxPdaSeedLengthExceededError,                     # Max PDA seed length exceeded
        2_800_008 => :InvalidSeedsPointOnCurveError,                     # Invalid seeds point on curve
        2_800_009 => :FailedToFindViablePdaBumpSeedError,                # Failed to find viable PDA bump seed
        2_800_010 => :PdaEndsWithPdaMarkerError,                         # PDA ends with PDA marker
        2_800_011 => :InvalidOffCurveAddressError,                       # Invalid off-curve address

        # ── Account errors ────────────────────────────────────────────────
        3_230_000 => :AccountNotFoundError,                              # Account not found
        3_230_001 => :OneOrMoreAccountsNotFoundError,                    # One or more accounts not found
        3_230_002 => :FailedToDecodeAccountError,                        # Failed to decode account
        3_230_003 => :ExpectedDecodedAccountError,                       # Expected decoded account
        3_230_004 => :ExpectedAllAccountsToBeDecodedError,               # Expected all accounts to be decoded

        # ── Subtle crypto errors ──────────────────────────────────────────
        3_610_000 => :SubtleCryptoDisallowedInInsecureContextError,      # Disallowed in insecure context
        3_610_001 => :SubtleCryptoDigestUnimplementedError,              # Digest function unimplemented
        3_610_002 => :SubtleCryptoEd25519AlgorithmUnimplementedError,    # Ed25519 algorithm unimplemented
        3_610_003 => :SubtleCryptoExportFunctionUnimplementedError,      # Export function unimplemented
        3_610_004 => :SubtleCryptoGenerateFunctionUnimplementedError,    # Generate function unimplemented
        3_610_005 => :SubtleCryptoSignFunctionUnimplementedError,        # Sign function unimplemented
        3_610_006 => :SubtleCryptoVerifyFunctionUnimplementedError,      # Verify function unimplemented
        3_610_007 => :SubtleCryptoCannotExportNonExtractableKeyError,    # Cannot export non-extractable key

        # ── Crypto errors ─────────────────────────────────────────────────
        3_611_000 => :CryptoRandomValuesFunctionUnimplementedError,      # Random values function unimplemented

        # ── Key errors ────────────────────────────────────────────────────
        3_704_000 => :InvalidKeyPairByteLengthError,                     # Invalid key pair byte length
        3_704_001 => :InvalidPrivateKeyByteLengthError,                  # Invalid private key byte length
        3_704_002 => :InvalidSignatureByteLengthError,                   # Invalid signature byte length
        3_704_003 => :SignatureStringLengthOutOfRangeError,              # Signature string length out of range
        3_704_004 => :PublicKeyMustMatchPrivateKeyError,                 # Public key must match private key
        3_704_005 => :InvalidBase58InGrindRegexError,                    # Invalid base58 in grind regex
        3_704_006 => :WriteKeyPairUnsupportedEnvironmentError,           # Write key pair unsupported environment

        # ── Filesystem errors ─────────────────────────────────────────────
        3_712_000 => :FsUnsupportedEnvironmentError,                     # Filesystem unsupported environment

        # ── Instruction errors ────────────────────────────────────────────
        4_128_000 => :InstructionExpectedToHaveAccountsError,            # Expected instruction to have accounts
        4_128_001 => :InstructionExpectedToHaveDataError,                # Expected instruction to have data
        4_128_002 => :InstructionProgramIdMismatchError,                 # Instruction program ID mismatch

        # ── Instruction error codes (from program execution) ──────────────
        4_615_000 => :InstructionErrorUnknownError,                      # Unknown instruction error
        4_615_001 => :InstructionErrorGenericError,                      # Generic instruction error
        4_615_002 => :InstructionErrorInvalidArgumentError,              # Invalid argument
        4_615_003 => :InstructionErrorInvalidInstructionDataError,       # Invalid instruction data
        4_615_004 => :InstructionErrorInvalidAccountDataError,           # Invalid account data
        4_615_005 => :InstructionErrorAccountDataTooSmallError,          # Account data too small
        4_615_006 => :InstructionErrorInsufficientFundsError,            # Insufficient funds
        4_615_007 => :InstructionErrorIncorrectProgramIdError,           # Incorrect program ID
        4_615_008 => :InstructionErrorMissingRequiredSignatureError,     # Missing required signature
        4_615_009 => :InstructionErrorAccountAlreadyInitializedError,    # Account already initialized
        4_615_010 => :InstructionErrorUninitializedAccountError,         # Uninitialized account
        4_615_011 => :InstructionErrorUnbalancedInstructionError,        # Unbalanced instruction
        4_615_012 => :InstructionErrorModifiedProgramIdError,            # Modified program ID
        4_615_013 => :InstructionErrorExternalAccountLamportSpendError,  # External account lamport spend
        4_615_014 => :InstructionErrorExternalAccountDataModifiedError,  # External account data modified
        4_615_015 => :InstructionErrorReadonlyLamportChangeError,        # Readonly lamport change
        4_615_016 => :InstructionErrorReadonlyDataModifiedError,         # Readonly data modified
        4_615_017 => :InstructionErrorDuplicateAccountIndexError,        # Duplicate account index
        4_615_018 => :InstructionErrorExecutableModifiedError,           # Executable modified
        4_615_019 => :InstructionErrorRentEpochModifiedError,            # Rent epoch modified
        4_615_020 => :InstructionErrorNotEnoughAccountKeysError,         # Not enough account keys
        4_615_021 => :InstructionErrorAccountDataSizeChangedError,       # Account data size changed
        4_615_022 => :InstructionErrorAccountNotExecutableError,         # Account not executable
        4_615_023 => :InstructionErrorAccountBorrowFailedError,          # Account borrow failed
        4_615_024 => :InstructionErrorAccountBorrowOutstandingError,     # Account borrow outstanding
        4_615_025 => :InstructionErrorDuplicateAccountOutOfSyncError,    # Duplicate account out of sync
        4_615_026 => :InstructionErrorCustomError,                       # Custom program error
        4_615_027 => :InstructionErrorInvalidError,                      # Invalid error
        4_615_028 => :InstructionErrorExecutableDataModifiedError,       # Executable data modified
        4_615_029 => :InstructionErrorExecutableLamportChangeError,      # Executable lamport change
        4_615_030 => :InstructionErrorExecutableAccountNotRentExemptError, # Executable account not rent exempt
        4_615_031 => :InstructionErrorUnsupportedProgramIdError,         # Unsupported program ID
        4_615_032 => :InstructionErrorCallDepthError,                    # Call depth exceeded
        4_615_033 => :InstructionErrorMissingAccountError,               # Missing account
        4_615_034 => :InstructionErrorReentrancyNotAllowedError,         # Reentrancy not allowed
        4_615_035 => :InstructionErrorMaxSeedLengthExceededError,        # Max seed length exceeded
        4_615_036 => :InstructionErrorInvalidSeedsError,                 # Invalid seeds
        4_615_037 => :InstructionErrorInvalidReallocError,               # Invalid realloc
        4_615_038 => :InstructionErrorComputationalBudgetExceededError,  # Computational budget exceeded
        4_615_039 => :InstructionErrorPrivilegeEscalationError,          # Privilege escalation
        4_615_040 => :InstructionErrorProgramEnvironmentSetupFailureError, # Program environment setup failure
        4_615_041 => :InstructionErrorProgramFailedToCompleteError,      # Program failed to complete
        4_615_042 => :InstructionErrorProgramFailedToCompileError,       # Program failed to compile
        4_615_043 => :InstructionErrorImmutableError,                    # Account is immutable
        4_615_044 => :InstructionErrorIncorrectAuthorityError,           # Incorrect authority
        4_615_045 => :InstructionErrorBorshIoError,                      # Borsh I/O error
        4_615_046 => :InstructionErrorAccountNotRentExemptError,         # Account not rent exempt
        4_615_047 => :InstructionErrorInvalidAccountOwnerError,          # Invalid account owner
        4_615_048 => :InstructionErrorArithmeticOverflowError,           # Arithmetic overflow
        4_615_049 => :InstructionErrorUnsupportedSysvarError,            # Unsupported sysvar
        4_615_050 => :InstructionErrorIllegalOwnerError,                 # Illegal owner
        4_615_051 => :InstructionErrorMaxAccountsDataAllocationsExceededError, # Max accounts data allocations exceeded
        4_615_052 => :InstructionErrorMaxAccountsExceededError,          # Max accounts exceeded
        4_615_053 => :InstructionErrorMaxInstructionTraceLengthExceededError, # Max instruction trace length exceeded
        4_615_054 => :InstructionErrorBuiltinProgramsMustConsumeComputeUnitsError, # Builtin programs must consume CUs

        # ── Signer errors ────────────────────────────────────────────────
        5_508_000 => :SignerAddressCannotHaveMultipleSignersError,        # Address cannot have multiple signers
        5_508_001 => :SignerExpectedKeyPairSignerError,                   # Expected key pair signer
        5_508_002 => :SignerExpectedMessageSignerError,                   # Expected message signer
        5_508_003 => :SignerExpectedMessageModifyingSignerError,          # Expected message-modifying signer
        5_508_004 => :SignerExpectedMessagePartialSignerError,            # Expected message partial signer
        5_508_005 => :SignerExpectedTransactionSignerError,               # Expected transaction signer
        5_508_006 => :SignerExpectedTransactionModifyingSignerError,      # Expected transaction-modifying signer
        5_508_007 => :SignerExpectedTransactionPartialSignerError,        # Expected transaction partial signer
        5_508_008 => :SignerExpectedTransactionSendingSignerError,        # Expected transaction sending signer
        5_508_009 => :SignerTransactionCannotHaveMultipleSendingSignersError, # Transaction cannot have multiple sending signers
        5_508_010 => :SignerTransactionSendingSignerMissingError,         # Transaction sending signer missing
        5_508_011 => :SignerWalletMultisignUnimplementedError,            # Wallet multisign unimplemented
        5_508_012 => :SignerWalletAccountCannotSignTransactionError,      # Wallet account cannot sign transaction

        # ── Offchain message errors ──────────────────────────────────────
        5_607_000 => :OffchainMessageMaximumLengthExceededError,         # Maximum length exceeded
        5_607_001 => :OffchainMessageRestrictedAsciiCharacterOutOfRangeError, # Restricted ASCII body character out of range
        5_607_002 => :OffchainMessageApplicationDomainStringLengthOutOfRangeError, # Application domain string length out of range
        5_607_003 => :OffchainMessageInvalidApplicationDomainByteLengthError, # Invalid application domain byte length
        5_607_004 => :OffchainMessageNumSignaturesMismatchError,         # Num signatures mismatch
        5_607_005 => :OffchainMessageNumRequiredSignersCannotBeZeroError, # Num required signers cannot be zero
        5_607_006 => :OffchainMessageVersionNumberNotSupportedError,     # Version number not supported
        5_607_007 => :OffchainMessageFormatMismatchError,                # Message format mismatch
        5_607_008 => :OffchainMessageLengthMismatchError,                # Message length mismatch
        5_607_009 => :OffchainMessageMustBeNonEmptyError,                # Message must be non-empty
        5_607_010 => :OffchainMessageNumEnvelopeSignaturesCannotBeZeroError, # Num envelope signatures cannot be zero
        5_607_011 => :OffchainMessageSignaturesMissingError,             # Signatures missing
        5_607_012 => :OffchainMessageEnvelopeSignersMismatchError,       # Envelope signers mismatch
        5_607_013 => :OffchainMessageAddressesCannotSignError,           # Addresses cannot sign offchain message
        5_607_014 => :OffchainMessageUnexpectedVersionError,             # Unexpected version
        5_607_015 => :OffchainMessageSignatoriesMustBeSortedError,       # Signatories must be sorted
        5_607_016 => :OffchainMessageSignatoriesMustBeUniqueError,       # Signatories must be unique
        5_607_017 => :OffchainMessageSignatureVerificationFailureError,  # Signature verification failure

        # ── Transaction errors (client-side) ─────────────────────────────
        5_663_000 => :TransactionInvokedProgramsCannotPayFeesError,      # Invoked programs cannot pay fees
        5_663_001 => :TransactionInvokedProgramsMustNotBeWritableError,  # Invoked programs must not be writable
        5_663_002 => :TransactionExpectedBlockhashLifetimeError,         # Expected blockhash lifetime
        5_663_003 => :TransactionExpectedNonceLifetimeError,             # Expected nonce lifetime
        5_663_004 => :TransactionVersionNumberOutOfRangeError,           # Version number out of range
        5_663_005 => :TransactionFailedToDecompileAddressLookupTableContentsMissingError, # ALT contents missing
        5_663_006 => :TransactionFailedToDecompileAddressLookupTableIndexOutOfRangeError, # ALT index out of range
        5_663_007 => :TransactionFailedToDecompileInstructionProgramAddressNotFoundError, # Instruction program address not found
        5_663_008 => :TransactionFailedToDecompileFeePayerMissingError,  # Fee payer missing during decompile
        5_663_009 => :TransactionSignaturesMissingError,                 # Signatures missing
        5_663_010 => :TransactionAddressMissingError,                    # Address missing
        5_663_011 => :TransactionFeePayerMissingError,                   # Fee payer missing
        5_663_012 => :TransactionFeePayerSignatureMissingError,          # Fee payer signature missing
        5_663_013 => :TransactionInvalidNonceInstructionsMissingError,   # Invalid nonce transaction instructions missing
        5_663_014 => :TransactionInvalidNonceFirstInstructionError,      # First instruction must be advance nonce
        5_663_015 => :TransactionAddressesCannotSignError,               # Addresses cannot sign transaction
        5_663_016 => :TransactionCannotEncodeWithEmptySignaturesError,   # Cannot encode with empty signatures
        5_663_017 => :TransactionMessageSignaturesMismatchError,         # Message signatures mismatch
        5_663_018 => :TransactionFailedToEstimateComputeLimitError,      # Failed to estimate compute limit
        5_663_019 => :TransactionFailedWhenSimulatingToEstimateComputeLimitError, # Failed simulating for compute limit
        5_663_020 => :TransactionExceedsSizeLimitError,                  # Transaction exceeds size limit
        5_663_021 => :TransactionVersionNumberNotSupportedError,         # Version number not supported
        5_663_022 => :TransactionNonceAccountCannotBeInLookupTableError, # Nonce account cannot be in lookup table
        5_663_023 => :TransactionMalformedMessageBytesError,             # Malformed message bytes
        5_663_024 => :TransactionCannotEncodeWithEmptyMessageBytesError, # Cannot encode with empty message bytes
        5_663_025 => :TransactionCannotDecodeEmptyBytesError,            # Cannot decode empty transaction bytes
        5_663_026 => :TransactionVersionZeroMustBeEncodedWithSignaturesFirstError, # V0 must encode signatures first
        5_663_027 => :TransactionSignatureCountTooHighError,             # Signature count too high for transaction bytes
        5_663_028 => :TransactionInvalidConfigMaskPriorityFeeBitsError,  # Invalid config mask priority fee bits
        5_663_029 => :TransactionInvalidNonceAccountIndexError,          # Invalid nonce account index
        5_663_030 => :TransactionInvalidConfigValueKindError,            # Invalid config value kind
        5_663_031 => :TransactionInstructionHeadersPayloadsMismatchError, # Instruction headers/payloads mismatch
        5_663_032 => :TransactionTooManySignerAddressesError,            # Too many signer addresses
        5_663_033 => :TransactionTooManyAccountAddressesError,           # Too many account addresses
        5_663_034 => :TransactionTooManyInstructionsError,               # Too many instructions
        5_663_035 => :TransactionTooManyAccountsInInstructionError,      # Too many accounts in instruction

        # ── Transaction error codes (from runtime) ───────────────────────
        7_050_000 => :TransactionErrorUnknownError,                      # Unknown transaction error
        7_050_001 => :TransactionErrorAccountInUseError,                 # Account in use
        7_050_002 => :TransactionErrorAccountLoadedTwiceError,           # Account loaded twice
        7_050_003 => :TransactionErrorAccountNotFoundError,              # Account not found
        7_050_004 => :TransactionErrorProgramAccountNotFoundError,       # Program account not found
        7_050_005 => :TransactionErrorInsufficientFundsForFeeError,      # Insufficient funds for fee
        7_050_006 => :TransactionErrorInvalidAccountForFeeError,         # Invalid account for fee
        7_050_007 => :TransactionErrorAlreadyProcessedError,             # Transaction already processed
        7_050_008 => :TransactionErrorBlockhashNotFoundError,            # Blockhash not found
        7_050_009 => :TransactionErrorCallChainTooDeepError,             # Call chain too deep
        7_050_010 => :TransactionErrorMissingSignatureForFeeError,       # Missing signature for fee
        7_050_011 => :TransactionErrorInvalidAccountIndexError,          # Invalid account index
        7_050_012 => :TransactionErrorSignatureFailureError,             # Signature failure
        7_050_013 => :TransactionErrorInvalidProgramForExecutionError,   # Invalid program for execution
        7_050_014 => :TransactionErrorSanitizeFailureError,              # Sanitize failure
        7_050_015 => :TransactionErrorClusterMaintenanceError,           # Cluster maintenance
        7_050_016 => :TransactionErrorAccountBorrowOutstandingError,     # Account borrow outstanding
        7_050_017 => :TransactionErrorWouldExceedMaxBlockCostLimitError, # Would exceed max block cost limit
        7_050_018 => :TransactionErrorUnsupportedVersionError,           # Unsupported version
        7_050_019 => :TransactionErrorInvalidWritableAccountError,       # Invalid writable account
        7_050_020 => :TransactionErrorWouldExceedMaxAccountCostLimitError, # Would exceed max account cost limit
        7_050_021 => :TransactionErrorWouldExceedAccountDataBlockLimitError, # Would exceed account data block limit
        7_050_022 => :TransactionErrorTooManyAccountLocksError,          # Too many account locks
        7_050_023 => :TransactionErrorAddressLookupTableNotFoundError,   # Address lookup table not found
        7_050_024 => :TransactionErrorInvalidAddressLookupTableOwnerError, # Invalid ALT owner
        7_050_025 => :TransactionErrorInvalidAddressLookupTableDataError, # Invalid ALT data
        7_050_026 => :TransactionErrorInvalidAddressLookupTableIndexError, # Invalid ALT index
        7_050_027 => :TransactionErrorInvalidRentPayingAccountError,     # Invalid rent paying account
        7_050_028 => :TransactionErrorWouldExceedMaxVoteCostLimitError,  # Would exceed max vote cost limit
        7_050_029 => :TransactionErrorWouldExceedAccountDataTotalLimitError, # Would exceed account data total limit
        7_050_030 => :TransactionErrorDuplicateInstructionError,         # Duplicate instruction
        7_050_031 => :TransactionErrorInsufficientFundsForRentError,     # Insufficient funds for rent
        7_050_032 => :TransactionErrorMaxLoadedAccountsDataSizeExceededError, # Max loaded accounts data size exceeded
        7_050_033 => :TransactionErrorInvalidLoadedAccountsDataSizeLimitError, # Invalid loaded accounts data size limit
        7_050_034 => :TransactionErrorResanitizationNeededError,         # Resanitization needed
        7_050_035 => :TransactionErrorProgramExecutionTemporarilyRestrictedError, # Program execution temporarily restricted
        7_050_036 => :TransactionErrorUnbalancedTransactionError,        # Unbalanced transaction

        # ── Instruction plan errors ──────────────────────────────────────
        7_618_000 => :InstructionPlanMessageCannotAccommodatePlanError,   # Message cannot accommodate plan
        7_618_001 => :InstructionPlanMessagePackerAlreadyCompleteError,   # Message packer already complete
        7_618_002 => :InstructionPlanEmptyError,                          # Empty instruction plan
        7_618_003 => :InstructionPlanFailedToExecuteTransactionPlanError, # Failed to execute transaction plan
        7_618_004 => :InstructionPlanNonDivisibleNotSupportedError,       # Non-divisible transaction plans not supported
        7_618_005 => :InstructionPlanFailedSingleResultNotFoundError,     # Failed single transaction plan result not found
        7_618_006 => :InstructionPlanUnexpectedError,                     # Unexpected instruction plan
        7_618_007 => :InstructionPlanUnexpectedTransactionPlanError,      # Unexpected transaction plan
        7_618_008 => :InstructionPlanUnexpectedTransactionPlanResultError, # Unexpected transaction plan result
        7_618_009 => :InstructionPlanExpectedSuccessfulResultError,       # Expected successful transaction plan result

        # ── Codec errors ─────────────────────────────────────────────────
        8_078_000 => :CodecCannotDecodeEmptyByteArrayError,              # Cannot decode empty byte array
        8_078_001 => :CodecInvalidByteLengthError,                       # Invalid byte length
        8_078_002 => :CodecExpectedFixedLengthError,                     # Expected fixed length
        8_078_003 => :CodecExpectedVariableLengthError,                  # Expected variable length
        8_078_004 => :CodecEncoderDecoderSizeCompatibilityMismatchError, # Encoder/decoder size compatibility mismatch
        8_078_005 => :CodecEncoderDecoderFixedSizeMismatchError,         # Encoder/decoder fixed size mismatch
        8_078_006 => :CodecEncoderDecoderMaxSizeMismatchError,           # Encoder/decoder max size mismatch
        8_078_007 => :CodecInvalidNumberOfItemsError,                    # Invalid number of items
        8_078_008 => :CodecEnumDiscriminatorOutOfRangeError,             # Enum discriminator out of range
        8_078_009 => :CodecInvalidDiscriminatedUnionVariantError,        # Invalid discriminated union variant
        8_078_010 => :CodecInvalidEnumVariantError,                      # Invalid enum variant
        8_078_011 => :CodecNumberOutOfRangeError,                        # Number out of range
        8_078_012 => :CodecInvalidStringForBaseError,                    # Invalid string for base
        8_078_013 => :CodecExpectedPositiveByteLengthError,              # Expected positive byte length
        8_078_014 => :CodecOffsetOutOfRangeError,                        # Offset out of range
        8_078_015 => :CodecInvalidLiteralUnionVariantError,              # Invalid literal union variant
        8_078_016 => :CodecLiteralUnionDiscriminatorOutOfRangeError,     # Literal union discriminator out of range
        8_078_017 => :CodecUnionVariantOutOfRangeError,                  # Union variant out of range
        8_078_018 => :CodecInvalidConstantError,                         # Invalid constant
        8_078_019 => :CodecExpectedZeroValueToMatchItemFixedSizeError,   # Expected zero value to match item fixed size
        8_078_020 => :CodecEncodedBytesMustNotIncludeSentinelError,      # Encoded bytes must not include sentinel
        8_078_021 => :CodecSentinelMissingInDecodedBytesError,           # Sentinel missing in decoded bytes
        8_078_022 => :CodecCannotUseLexicalValuesAsEnumDiscriminatorsError, # Cannot use lexical values as enum discriminators
        8_078_023 => :CodecExpectedDecoderToConsumeEntireByteArrayError, # Expected decoder to consume entire byte array
        8_078_024 => :CodecInvalidPatternMatchValueError,                # Invalid pattern match value
        8_078_025 => :CodecInvalidPatternMatchBytesError,                # Invalid pattern match bytes

        # ── RPC transport errors ─────────────────────────────────────────
        8_100_000 => :RpcIntegerOverflowError,                           # Integer overflow
        8_100_001 => :RpcTransportHttpHeaderForbiddenError,              # HTTP header forbidden
        8_100_002 => :RpcTransportHttpError,                             # HTTP transport error
        8_100_003 => :RpcApiPlanMissingForMethodError,                   # API plan missing for RPC method

        # ── RPC subscription errors ──────────────────────────────────────
        8_190_000 => :RpcSubscriptionCannotCreatePlanError,              # Cannot create subscription plan
        8_190_001 => :RpcSubscriptionExpectedServerSubscriptionIdError,  # Expected server subscription ID
        8_190_002 => :RpcSubscriptionChannelClosedBeforeMessageBufferedError, # Channel closed before message buffered
        8_190_003 => :RpcSubscriptionChannelConnectionClosedError,       # Channel connection closed
        8_190_004 => :RpcSubscriptionChannelFailedToConnectError,        # Channel failed to connect

        # ── Program client errors ────────────────────────────────────────
        8_500_000 => :ProgramClientInsufficientAccountMetasError,        # Insufficient account metas
        8_500_001 => :ProgramClientUnrecognizedInstructionTypeError,     # Unrecognized instruction type
        8_500_002 => :ProgramClientFailedToIdentifyInstructionError,     # Failed to identify instruction
        8_500_003 => :ProgramClientUnexpectedResolvedInstructionInputTypeError, # Unexpected resolved instruction input type
        8_500_004 => :ProgramClientResolvedInstructionInputMustBeNonNullError, # Resolved instruction input must be non-null
        8_500_005 => :ProgramClientUnrecognizedAccountTypeError,         # Unrecognized account type
        8_500_006 => :ProgramClientFailedToIdentifyAccountError,         # Failed to identify account

        # ── Wallet errors ────────────────────────────────────────────────
        8_900_000 => :WalletNotConnectedError,                           # Wallet not connected
        8_900_001 => :WalletNoSignerConnectedError,                      # No signer connected
        8_900_002 => :WalletSignerNotAvailableError,                     # Signer not available

        # ── Invariant violation errors ───────────────────────────────────
        9_900_000 => :InvariantViolationSubscriptionIteratorStateMissingError, # Subscription iterator state missing
        9_900_001 => :InvariantViolationSubscriptionIteratorMustNotPollBeforeResolvingError, # Must not poll before resolving existing promise
        9_900_002 => :InvariantViolationCachedAbortableIterableCacheEntryMissingError, # Cached abortable iterable cache entry missing
        9_900_003 => :InvariantViolationSwitchMustBeExhaustiveError,     # Switch must be exhaustive
        9_900_004 => :InvariantViolationDataPublisherChannelUnimplementedError, # Data publisher channel unimplemented
        9_900_005 => :InvariantViolationInvalidInstructionPlanKindError,  # Invalid instruction plan kind
        9_900_006 => :InvariantViolationInvalidTransactionPlanKindError   # Invalid transaction plan kind
      }.freeze

      # Formats a response to an error, returning the most specific subclass
      # when the error code is recognized.
      #
      # @param response [Hash] The JSON-RPC response
      # @return [Solace::Errors::RPCError] The formatted error
      def self.format_response(response)
        code = response['error']['code']
        message = response['error']['message']
        data = response['error']['data']

        klass = if (name = CODE_MAP[code])
                  Errors.const_defined?(name, false) ? Errors.const_get(name) : Errors.const_set(name, Class.new(self))
                else
                  self
                end

        klass.new(
          "RPC error #{code}: #{message}",
          rpc_data: data,
          rpc_code: code,
          rpc_message: message
        )
      end

      # @return [Hash] The error as a hash
      def to_h = { code: rpc_code, message: rpc_message, data: rpc_data }
    end
  end
end

# frozen_string_literal: true

module Solace
  module Errors
    # Specific RPC error subclasses mapped to JSON-RPC and Solana error codes.
    #
    # These allow consumers to rescue specific RPC failures:
    #
    # @example Rescuing a specific RPC error
    #   begin
    #     connection.send_transaction(transaction)
    #   rescue Solace::Errors::InvalidParamsError => e
    #     puts "Bad params: #{e.rpc_message}"
    #   rescue Solace::Errors::RPCError => e
    #     puts "Other RPC error: #{e.message}"
    #   end
    #
    # @since 0.1.4

    # ── Standard JSON-RPC 2.0 errors ──────────────────────────────────────

    # Raised when the server receives invalid JSON (-32700).
    # @since 0.1.4
    class ServerParseError < RPCError; end

    # Raised when the JSON sent is not a valid JSON-RPC request (-32600).
    # @since 0.1.4
    class InvalidRequestError < RPCError; end

    # Raised when the requested RPC method does not exist (-32601).
    # @since 0.1.4
    class MethodNotFoundError < RPCError; end

    # Raised when invalid method parameters are provided (-32602).
    # @since 0.1.4
    class InvalidParamsError < RPCError; end

    # Raised when an internal JSON-RPC error occurs (-32603).
    # @since 0.1.4
    class InternalError < RPCError; end

    # ── Solana-specific RPC errors ────────────────────────────────────────

    # Raised when the requested block/slot is not available (-32001).
    # @since 0.1.4
    class BlockNotAvailableError < RPCError; end

    # Raised when the node is behind or not fully synced (-32002).
    # @since 0.1.4
    class NodeUnhealthyError < RPCError; end

    # Raised when transaction signature verification or precompile check fails (-32003).
    # @since 0.1.4
    class TransactionPrecompileVerificationFailureError < RPCError; end

    # Raised when the requested slot was skipped (-32004).
    # @since 0.1.4
    class SlotSkippedError < RPCError; end

    # Raised when no snapshot is available (-32005).
    # @since 0.1.4
    class NoSnapshotError < RPCError; end

    # Raised when a slot was skipped in long-term storage (-32006).
    # @since 0.1.4
    class LongTermStorageSlotSkippedError < RPCError; end

    # Raised when the requested key was excluded from the secondary index (-32007).
    # @since 0.1.4
    class KeyExcludedFromSecondaryIndexError < RPCError; end

    # Raised when transaction history is not available for the requested range (-32008).
    # @since 0.1.4
    class TransactionHistoryNotAvailableError < RPCError; end

    # Raised when a scan/iteration error occurs (-32009).
    # @since 0.1.4
    class ScanError < RPCError; end

    # Raised when the number of transaction signatures doesn't match expected (-32010).
    # @since 0.1.4
    class TransactionSignatureLengthMismatchError < RPCError; end

    # Raised when the block's confirmation status is not yet available (-32011).
    # @since 0.1.4
    class BlockStatusNotAvailableError < RPCError; end

    # Raised when the transaction uses an unsupported version (-32012).
    # @since 0.1.4
    class UnsupportedTransactionVersionError < RPCError; end

    # Raised when the minimum context slot has not yet been reached (-32013).
    # @since 0.1.4
    class MinContextSlotNotReachedError < RPCError; end
  end
end

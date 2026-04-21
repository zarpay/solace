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

      # Maps JSON-RPC error codes to specific error subclasses.
      # Codes not in this map will raise a generic {RPCError}.
      #
      # @return [Hash{Integer => Class}]
      CODE_MAP = {
        # Standard JSON-RPC 2.0 errors
        -32_700 => :ServerParseError,
        -32_600 => :InvalidRequestError,
        -32_601 => :MethodNotFoundError,
        -32_602 => :InvalidParamsError,
        -32_603 => :InternalError,
        # Solana-specific errors
        -32_001 => :BlockNotAvailableError,
        -32_002 => :NodeUnhealthyError,
        -32_003 => :TransactionPrecompileVerificationFailureError,
        -32_004 => :SlotSkippedError,
        -32_005 => :NoSnapshotError,
        -32_006 => :LongTermStorageSlotSkippedError,
        -32_007 => :KeyExcludedFromSecondaryIndexError,
        -32_008 => :TransactionHistoryNotAvailableError,
        -32_009 => :ScanError,
        -32_010 => :TransactionSignatureLengthMismatchError,
        -32_011 => :BlockStatusNotAvailableError,
        -32_012 => :UnsupportedTransactionVersionError,
        -32_013 => :MinContextSlotNotReachedError
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

        klass = CODE_MAP[code] ? Errors.const_get(CODE_MAP[code]) : self

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

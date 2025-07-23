# frozen_string_literal: true

# Constants module
#
# Contains constants used across the library.
#
# @return [Module] Constants module
module Solace
  module Constants
    # @!const SYSTEM_PROGRAM_ID
    #   The public key of the System Program (native SOL transfers, account creation, etc)
    #   This is the same across all Solana clusters
    # @return [String]
    SYSTEM_PROGRAM_ID = '11111111111111111111111111111111'

    # @!const SYSVAR_RENT_PROGRAM_ID
    #   The public key of the Rent Program
    #   This is the same across all Solana clusters
    # @return [String]
    SYSVAR_RENT_PROGRAM_ID = 'SysvarRent111111111111111111111111111111111'

    # @!const COMPUTE_BUDGET_PROGRAM_ID
    #   The public key of the Compute Budget Program
    #   This is the same across all Solana clusters
    # @return [String]
    COMPUTE_BUDGET_PROGRAM_ID = 'ComputeBudget111111111111111111111111111111'

    # @!const TOKEN_PROGRAM_ID
    #   The public key of the SPL Token Program
    #   This is the same across all Solana clusters
    # @return [String]
    TOKEN_PROGRAM_ID = 'TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA'

    # @!const ASSOCIATED_TOKEN_ACCOUNT_PROGRAM_ID
    #   The public key of the Associated Token Account Program
    #   This is the same across all Solana clusters
    # @return [String]
    ASSOCIATED_TOKEN_ACCOUNT_PROGRAM_ID = 'ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL'

    # @!const MEMO_PROGRAM_ID
    #   The public key of the Memo Program
    #   This is the same across all Solana clusters
    # @return [String]
    MEMO_PROGRAM_ID = 'MemoSq4gqABAXKb96qnH8TysNcWxMyWCqXgDLGmfcHr'

    # @!const ADDRESS_LOOKUP_TABLE_PROGRAM_ID
    #   The public key of the Address Lookup Table Program
    #   This is the same across all Solana clusters
    # @return [String]
    ADDRESS_LOOKUP_TABLE_PROGRAM_ID = 'AddressLookupTab1e1111111111111111111111111'
  end
end

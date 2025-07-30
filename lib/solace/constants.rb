# frozen_string_literal: true

# Constants module
#
# Contains constants used across the library.
#
# @return [Module] Constants module
module Solace
  module Constants
    # @!attribute SYSTEM_PROGRAM_ID
    #   The public key of the System Program (native SOL transfers, account creation, etc)
    #   This is the same across all Solana clusters
    SYSTEM_PROGRAM_ID = '11111111111111111111111111111111'

    # @!attribute SYSVAR_RENT_PROGRAM_ID
    #   The public key of the Rent Program
    #   This is the same across all Solana clusters
    SYSVAR_RENT_PROGRAM_ID = 'SysvarRent111111111111111111111111111111111'

    # @!attribute COMPUTE_BUDGET_PROGRAM_ID
    #   The public key of the Compute Budget Program
    #   This is the same across all Solana clusters
    COMPUTE_BUDGET_PROGRAM_ID = 'ComputeBudget111111111111111111111111111111'

    # @!attribute TOKEN_PROGRAM_ID
    #   The public key of the SPL Token Program
    #   This is the same across all Solana clusters
    TOKEN_PROGRAM_ID = 'TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA'

    # @!attribute ASSOCIATED_TOKEN_ACCOUNT_PROGRAM_ID
    #   The public key of the Associated Token Account Program
    #   This is the same across all Solana clusters
    ASSOCIATED_TOKEN_ACCOUNT_PROGRAM_ID = 'ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL'

    # @!attribute MEMO_PROGRAM_ID
    #   The public key of the Memo Program
    #   This is the same across all Solana clusters
    MEMO_PROGRAM_ID = 'MemoSq4gqABAXKb96qnH8TysNcWxMyWCqXgDLGmfcHr'

    # @!attribute ADDRESS_LOOKUP_TABLE_PROGRAM_ID
    #   The public key of the Address Lookup Table Program
    #   This is the same across all Solana clusters
    ADDRESS_LOOKUP_TABLE_PROGRAM_ID = 'AddressLookupTab1e1111111111111111111111111'
  end
end

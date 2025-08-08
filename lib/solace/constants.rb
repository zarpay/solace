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

    # Loads the constants declared in a YAML file
    #
    # Developers require adding program addresses and mint accounts that will not
    # be added directly to Solace. This method allows for loading those constants
    # from a YAML file and extends the Constants module with them.
    #
    # The YAML file should be a hash of key-value pairs, where the key is the constant
    # name and the value is the constant value.
    #
    # @example
    #   # constants.yml
    #   devnet:
    #     my_program_id: some_devnet_program_id
    #     squads_program_id: some_devnet_program_id
    #     usdc_mint_account: some_devnet_program_id
    #     usdt_mint_account: some_devnet_program_id
    #
    #   mainnet:
    #     my_program_id: some_mainnet_program_id
    #     squads_program_id: some_mainnet_program_id
    #     usdc_mint_account: some_mainnet_program_id
    #     usdt_mint_account: some_mainnet_program_id
    #
    # @example
    #   Solace::Constants.load(
    #     path: '/home/user/my-project/config/constants.yml',
    #     namespace: 'devnet',
    #     protect_overrides: false
    #   )
    #
    #   Solace::Constants::MY_PROGRAM_ID
    #   Solace::Constants::SQUADS_PROGRAM_ID
    #   Solace::Constants::USDC_MINT_ACCOUNT
    #   Solace::Constants::USDT_MINT_ACCOUNT
    #
    # @param path [String] The path to the YAML file
    # @param namespace [String] The namespace to load the constants from
    # @param protect_overrides [Boolean] Whether to protect constants that are already defined
    # @return [void]
    # @raise [ArgumentError] If protect_overrides is on and a constant is already defined
    def self.load(
      path:,
      namespace: 'default',
      protect_overrides: true
    )
      content = YAML.load_file(path)

      content[namespace].each do |key, value|
        if const_defined?(key.upcase)
          raise ArgumentError, "Constant #{key} is already defined" if protect_overrides

          remove_const(key.upcase)
        end

        const_set(key.upcase, value)
      end
    end
  end
end

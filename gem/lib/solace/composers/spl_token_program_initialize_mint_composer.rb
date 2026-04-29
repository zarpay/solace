# frozen_string_literal: true

module Solace
  module Composers
    # Composer for initializing a mint via the SPL Token Program.
    #
    # This composer resolves and orders the required accounts for an `InitializeMint` instruction,
    # sets up their access permissions, and delegates construction to the appropriate
    # instruction builder (`Instructions::SplToken::InitializeMintInstruction`).
    #
    # It is used for initializing a new SPL Token mint.
    #
    # Required accounts:
    # - **Mint Account**: the mint account to initialize (writable, non-signer)
    #
    # @example Compose and build an initialize_mint instruction
    #  composer = SplTokenProgramInitializeMintComposer.new(
    #    decimals: 6,
    #    mint_authority: mint_authority_pubkey,
    #    freeze_authority: freeze_authority_pubkey,
    #    mint_account: mint_address,
    #  )
    #
    # @see Instructions::SplToken::InitializeMintInstruction
    # @since 0.1.0
    class SplTokenProgramInitializeMintComposer < Base
      # Extracts the mint account address from the params
      #
      # @return [String] The mint account address
      def mint_account
        params[:mint_account].to_s
      end

      # Returns the rent sysvar address
      #
      # @return [String] The rent sysvar address
      def rent_sysvar
        Constants::SYSVAR_RENT_PROGRAM_ID.to_s
      end

      # Returns the spl token program id
      #
      # @return [String] The spl token program id
      def spl_token_program
        Constants::TOKEN_PROGRAM_ID.to_s
      end

      # Extracts the mint authority address from the params
      #
      # @return [String] The mint authority address
      def mint_authority
        params[:mint_authority].to_s
      end

      # Extracts the freeze authority address from the params
      #
      # @return [String] The freeze authority address
      def freeze_authority
        params[:freeze_authority]&.to_s
      end

      # Returns the decimals for the mint
      #
      # @return [Integer] The decimals for the mint
      def decimals
        params[:decimals]
      end

      # Setup accounts required for transfer instruction
      # Called automatically during initialization
      #
      # @return [void]
      def setup_accounts
        account_context.add_writable_nonsigner(mint_account)
        account_context.add_readonly_nonsigner(rent_sysvar)
        account_context.add_readonly_nonsigner(spl_token_program)
      end

      # Build instruction with resolved account indices
      #
      # @param account_context [Utils::AccountContext] The account context
      # @return [Solace::Instruction]
      def build_instruction(account_context)
        Instructions::SplToken::InitializeMintInstruction.build(
          mint_account_index: account_context.index_of(mint_account),
          rent_sysvar_index: account_context.index_of(rent_sysvar),
          program_index: account_context.index_of(spl_token_program),
          decimals: decimals,
          mint_authority: mint_authority,
          freeze_authority: freeze_authority
        )
      end
    end
  end
end

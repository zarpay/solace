# frozen_string_literal: true

module Solace
  module Composers
    # Composer for creating a compute budget set compute unit price instruction.
    #
    # This composer resolves and orders the required accounts for a `SetComputeUnitPrice`
    # instruction, sets up their access permissions, and delegates construction to the
    # appropriate instruction builder (`Instructions::ComputeBudget::SetComputeUnitPriceInstruction`).
    #
    # It is used for attaching a priority fee to a transaction.
    #
    # Required accounts:
    # - **Program**: Compute Budget program (readonly, non-signer)
    #
    # @example Compose and build a set compute unit price instruction
    #   composer = ComputeBudgetProgramSetComputeUnitPriceComposer.new(
    #     micro_lamports: 50_000
    #   )
    #
    # @see Instructions::ComputeBudget::SetComputeUnitPriceInstruction
    # @since 0.1.7
    class ComputeBudgetProgramSetComputeUnitPriceComposer < Base
      # Extracts the price per compute unit from the params
      #
      # @return [Integer] The price per compute unit (in micro-lamports)
      def micro_lamports
        params[:micro_lamports]
      end

      # Returns the compute budget program id
      #
      # @return [String] The compute budget program id
      def compute_budget_program
        Constants::COMPUTE_BUDGET_PROGRAM_ID.to_s
      end

      # Setup accounts required for set compute unit price instruction
      # Called automatically during initialization
      #
      # @return [void]
      def setup_accounts
        account_context.add_readonly_nonsigner(compute_budget_program)
      end

      # Build instruction with resolved account indices
      #
      # @param account_context [Utils::AccountContext] The account context
      # @return [Solace::Instruction]
      def build_instruction(account_context)
        Instructions::ComputeBudget::SetComputeUnitPriceInstruction.build(
          micro_lamports: micro_lamports,
          program_index:  account_context.index_of(compute_budget_program)
        )
      end
    end
  end
end

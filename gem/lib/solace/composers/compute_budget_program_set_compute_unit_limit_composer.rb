# frozen_string_literal: true

module Solace
  module Composers
    # Composer for creating a compute budget set compute unit limit instruction.
    #
    # This composer resolves and orders the required accounts for a `SetComputeUnitLimit`
    # instruction, sets up their access permissions, and delegates construction to the
    # appropriate instruction builder (`Instructions::ComputeBudget::SetComputeUnitLimitInstruction`).
    #
    # It is used for capping the compute units a transaction may consume.
    #
    # Required accounts:
    # - **Program**: Compute Budget program (readonly, non-signer)
    #
    # @example Compose and build a set compute unit limit instruction
    #   composer = ComputeBudgetProgramSetComputeUnitLimitComposer.new(
    #     units: 200_000
    #   )
    #
    # @see Instructions::ComputeBudget::SetComputeUnitLimitInstruction
    # @since 0.1.7
    class ComputeBudgetProgramSetComputeUnitLimitComposer < Base
      # Extracts the compute unit limit from the params
      #
      # @return [Integer] The compute unit limit
      def units
        params[:units]
      end

      # Returns the compute budget program id
      #
      # @return [String] The compute budget program id
      def compute_budget_program
        Constants::COMPUTE_BUDGET_PROGRAM_ID.to_s
      end

      # Setup accounts required for set compute unit limit instruction
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
        Instructions::ComputeBudget::SetComputeUnitLimitInstruction.build(
          units:         units,
          program_index: account_context.index_of(compute_budget_program)
        )
      end
    end
  end
end

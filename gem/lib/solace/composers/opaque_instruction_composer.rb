# frozen_string_literal: true

module Solace
  module Composers
    # Composer for an instruction it does not interpret.
    #
    # Where every other composer derives its accounts' roles from domain
    # arguments, this one is handed the program id, the accounts in order, the
    # data, and an {Utils::AccountContext} declaring each account's role, and
    # rebuilds the instruction by index against whatever context it is
    # composed into. It is what {Solace::TransactionDecomposer} answers for
    # each instruction of a transaction taken apart, and what a caller reaches
    # for to rebuild one of those with an account swapped out.
    #
    # @example Rebuild a recovered instruction with a different rent payer
    #   roles = Solace::Utils::AccountContext.new
    #   roles.merge_from(recovered.account_context)
    #   roles.add_writable_signer(sponsor)
    #
    #   composer = Solace::Composers::OpaqueInstructionComposer.new(
    #     program_id: recovered.program_id,
    #     accounts:   [sponsor, *recovered.accounts.drop(1)],
    #     data:       recovered.data,
    #     roles:      roles
    #   )
    #
    # @since 0.1.9
    class OpaqueInstructionComposer < Base
      # The program the instruction invokes
      #
      # @return [String] The program id
      def program_id
        params[:program_id].to_s
      end

      # The accounts the instruction touches, in order
      #
      # @return [Array<String>] The pubkeys
      def accounts
        @accounts ||= params[:accounts].map(&:to_s)
      end

      # The instruction data, untouched
      #
      # @return [Array<Integer>] The data bytes
      def data
        params[:data]
      end

      # The context declaring each account's role
      #
      # @return [Utils::AccountContext]
      def roles
        params[:roles]
      end

      # Declare every account with the role given for it, plus the program
      #
      # @return [void]
      # @raise [ArgumentError] When an account has no role declared
      def setup_accounts
        accounts.each do |pubkey|
          raise ArgumentError, "No role declared for account #{pubkey}" unless roles.pubkey_account_map.key?(pubkey)

          account_context.merge_account(pubkey, signer: roles.signer?(pubkey), writable: roles.writable?(pubkey))
        end

        account_context.add_readonly_nonsigner(program_id)
      end

      # Build the instruction with indices resolved against the given context
      #
      # @param account_context [Utils::AccountContext] The account context
      # @return [Solace::Instruction]
      def build_instruction(account_context)
        Solace::Instruction.new.tap do |instruction|
          instruction.program_index = account_context.index_of(program_id)
          instruction.accounts      = accounts.map { |pubkey| account_context.index_of(pubkey) }
          instruction.data          = data
        end
      end
    end
  end
end

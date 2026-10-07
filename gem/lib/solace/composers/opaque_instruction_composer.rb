# frozen_string_literal: true

module Solace
  module Composers
    # Composer for an instruction it does not interpret.
    #
    # Where every other composer derives its account metas from domain
    # arguments, this one declares exactly the program id, accounts and data it
    # was given, and rebuilds the instruction by index against whatever context
    # it is composed into. It is what {Solace::TransactionDecomposer} answers
    # for each instruction of a transaction taken apart, and what a caller
    # reaches for to rebuild one of those with an account swapped out.
    #
    # @example Rebuild a recovered instruction with a different rent payer
    #   accounts = recovered.accounts.dup
    #   accounts[0] = { pubkey: sponsor, signer: true, writable: true }
    #
    #   composer = Solace::Composers::OpaqueInstructionComposer.new(
    #     program_id: recovered.program_id,
    #     accounts:   accounts,
    #     data:       recovered.data
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

      # The accounts the instruction touches, in order, with their flags
      #
      # Pubkeys are answered as strings whatever they were given as, like
      # every other composer's addresses.
      #
      # @return [Array<Hash>] `{ pubkey: String, signer: Boolean, writable: Boolean }` per account
      def accounts
        @accounts ||= params[:accounts].map { |account| account.merge(pubkey: account[:pubkey].to_s) }
      end

      # The instruction data, untouched
      #
      # @return [Array<Integer>] The data bytes
      def data
        params[:data]
      end

      # Declare every account with the flags it was given, plus the program
      #
      # @return [void]
      def setup_accounts
        accounts.each { |account| declare(account) }
        account_context.add_readonly_nonsigner(program_id)
      end

      # Build the instruction with indices resolved against the given context
      #
      # @param account_context [Utils::AccountContext] The account context
      # @return [Solace::Instruction]
      def build_instruction(account_context)
        Solace::Instruction.new.tap do |instruction|
          instruction.program_index = account_context.index_of(program_id)
          instruction.accounts      = accounts.map { |account| account_context.index_of(account[:pubkey]) }
          instruction.data          = data
        end
      end

      private

      # Declare one account on the local context with its flags
      #
      # @param account [Hash] The account meta
      def declare(account)
        pubkey = account[:pubkey]

        if account[:signer] && account[:writable]
          account_context.add_writable_signer(pubkey)
        elsif account[:signer]
          account_context.add_readonly_signer(pubkey)
        elsif account[:writable]
          account_context.add_writable_nonsigner(pubkey)
        else
          account_context.add_readonly_nonsigner(pubkey)
        end
      end
    end
  end
end

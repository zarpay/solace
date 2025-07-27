# frozen_string_literal: true

module Solace
  module Composers
    # Composer for System Program transfer instructions
    class SystemProgramTransferComposer < Base
      # Define accounts required for transfer instruction
      #
      # @param from [Solace::Keypair] The sender keypair
      # @param to [String|Solace::Keypair] The recipient address or keypair
      # @param lamports [Integer] Amount to transfer (in lamports)
      # @return [Hash] Account context information
      def accounts(from:, to:, lamports:)
        context = Utils::AccountContext.new
        
        # From account is signer and writable (pays lamports)
        context.signer(:from, from)
        
        # To account is writable (receives lamports)
        to_pubkey = to.is_a?(String) ? to : to.address
        context.writable(:to, to_pubkey)
        
        # System program
        context.program(:system_program, Solace::Constants::SYSTEM_PROGRAM_ID)
        
        context.compile
      end

      # Build instruction with resolved account indices
      #
      # @param indices [Hash] Account name to index mapping
      # @param lamports [Integer] Amount to transfer (in lamports)
      # @return [Solace::Instruction]
      def instruction(indices:, lamports:, from: nil, to: nil)
        Instructions::SystemProgram::TransferInstruction.build(
          lamports: lamports,
          to_index: indices[:to],
          from_index: indices[:from],
          program_index: indices[:system_program]
        )
      end
    end
  end
end
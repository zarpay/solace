# frozen_string_literal: true

# Test-only composers for the Address Lookup Table program, used to provision
# on-chain tables for the versioned-transaction tests. The gem ships no ALT
# program composers — composed transactions only reference tables that already
# exist on chain.
module LookupTableProgram
  # Shared shape of the CreateLookupTable and ExtendLookupTable instructions:
  # both take [table, authority, payer, system program], and in these tests the
  # authority and payer are the same signer. Subclasses supply the data bytes.
  class BaseComposer < Solace::Composers::Base
    def setup_accounts
      account_context.add_writable_nonsigner(params[:table])
      account_context.add_writable_signer(params[:payer])
      account_context.add_readonly_nonsigner(Solace::Constants::SYSTEM_PROGRAM_ID)
      account_context.add_readonly_nonsigner(Solace::Constants::ADDRESS_LOOKUP_TABLE_PROGRAM_ID)
    end

    def build_instruction(account_context)
      Solace::Instruction.new.tap do |ix|
        ix.program_index = account_context.index_of(Solace::Constants::ADDRESS_LOOKUP_TABLE_PROGRAM_ID)
        ix.accounts      = account_indices(account_context)
        ix.data          = instruction_data
      end
    end

    private

    # [table, authority, payer, system program]
    def account_indices(account_context)
      [
        account_context.index_of(params[:table]),
        account_context.index_of(params[:payer]),
        account_context.index_of(params[:payer]),
        account_context.index_of(Solace::Constants::SYSTEM_PROGRAM_ID)
      ]
    end
  end

  # Composer for the CreateLookupTable instruction
  class CreateComposer < BaseComposer
    private

    # [u32 discriminator = 0] + [u64 recent slot] + [u8 bump]
    def instruction_data
      [0, 0, 0, 0] +
        Solace::Utils::Codecs.encode_le_u64(params[:recent_slot]).bytes +
        [params[:bump]]
    end
  end

  # Composer for the ExtendLookupTable instruction
  class ExtendComposer < BaseComposer
    private

    # [u32 discriminator = 2] + [u64 number of addresses] + [addresses]
    def instruction_data
      [2, 0, 0, 0] +
        Solace::Utils::Codecs.encode_le_u64(params[:addresses].length).bytes +
        params[:addresses].flat_map { |address| Solace::Utils::Codecs.base58_to_bytes(address) }
    end
  end
end

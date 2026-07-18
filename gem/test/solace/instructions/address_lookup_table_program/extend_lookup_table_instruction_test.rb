# frozen_string_literal: true

require 'test_helper'

describe Solace::Instructions::AddressLookupTableProgram::ExtendLookupTableInstruction do
  describe '.build' do
    let(:recipient1) { Solace::Keypair.generate.address }
    let(:recipient2) { Solace::Keypair.generate.address }

    let(:ix) do
      Solace::Instructions::AddressLookupTableProgram::ExtendLookupTableInstruction.build(
        addresses:            [recipient1, recipient2],
        program_index:        4,
        table_index:          1,
        authority_index:      0,
        payer_index:          0,
        system_program_index: 3
      )
    end

    it 'returns an instruction' do
      assert_kind_of Solace::Instruction, ix
    end

    it 'sets the program index' do
      assert_equal 4, ix.program_index
    end

    it 'orders the accounts [table, authority, payer, system_program]' do
      assert_equal [1, 0, 0, 3], ix.accounts
    end

    it 'encodes the discriminator, a u64 count, and the packed addresses' do
      expected = [2, 0, 0, 0] +
                 [2].pack('Q<').bytes +
                 Solace::Utils::Codecs.base58_to_bytes(recipient1) +
                 Solace::Utils::Codecs.base58_to_bytes(recipient2)

      assert_equal expected, ix.data
    end
  end
end

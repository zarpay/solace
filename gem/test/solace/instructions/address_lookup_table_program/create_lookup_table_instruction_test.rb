# frozen_string_literal: true

require 'test_helper'

describe Solace::Instructions::AddressLookupTableProgram::CreateLookupTableInstruction do
  describe '.build' do
    let(:ix) do
      Solace::Instructions::AddressLookupTableProgram::CreateLookupTableInstruction.build(
        recent_slot:          123,
        bump:                 254,
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

    it 'encodes the discriminator, recent slot, and bump' do
      assert_equal [0, 0, 0, 0] + [123].pack('Q<').bytes + [254], ix.data
    end
  end
end

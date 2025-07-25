# frozen_string_literal: true

require 'test_helper'

describe Solace::Instructions::SystemProgram::TransferCheckedInstruction do
  describe '.build' do
    let(:amount) { 100 }
    let(:decimals) { 6 }

    # Build a transfer instruction
    let(:ix) do
      Solace::Instructions::SystemProgram::TransferCheckedInstruction.build(
        amount: amount,
        decimals: decimals,
        to_index: 0,
        from_index: 1,
        mint_index: 2,
        authority_index: 4
      )
    end

    it 'returns an instruction' do
      assert_kind_of Solace::Instruction, ix
    end

    it 'sets the default program index' do
      assert_equal 3, ix.program_index
    end

    it 'has the correct accounts' do
      assert_equal [1, 2, 0, 4], ix.accounts
    end

    it 'has the correct data' do
      assert_equal [12] + [amount].pack('Q<').bytes + [decimals], ix.data
    end

    describe 'with custom program index' do
      let(:program_index) { 5 }

      let(:ix_with_custom_program_index) do
        Solace::Instructions::SystemProgram::TransferCheckedInstruction.build(
          amount: amount,
          decimals: decimals,
          to_index: 0,
          from_index: 1,
          mint_index: 2,
          authority_index: 4,
          program_index: program_index
        )
      end

      it 'sets the custom program index' do
        assert_equal program_index, ix_with_custom_program_index.program_index
      end
    end
  end
end

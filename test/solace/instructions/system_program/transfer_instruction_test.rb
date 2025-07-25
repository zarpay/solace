# frozen_string_literal: true

require_relative '../../test_helper'

describe Solace::Instructions::SystemProgram::TransferInstruction do
  describe '.build' do
    # Build a transfer instruction
    let(:ix) do
      Solace::Instructions::SystemProgram::TransferInstruction.build(
        to_index: 1,
        from_index: 0,
        program_index: 2,
        lamports: 100_000_000
      )
    end

    it 'returns an instruction' do
      assert_kind_of Solace::Instruction, ix
    end

    it 'sets the default program index' do
      assert_equal 2, ix.program_index
    end

    it 'has the correct accounts' do
      assert_equal [0, 1], ix.accounts
    end

    it 'has the correct data' do
      assert_equal [2, 0, 0, 0] + [100_000_000].pack('Q<').bytes, ix.data
    end

    describe 'with custom program index' do
      let(:ix_with_custom_program_index) do
        Solace::Instructions::SystemProgram::TransferInstruction.build(
          to_index: 0,
          from_index: 1,
          program_index: 3,
          lamports: 100_000
        )
      end

      it 'sets the custom program index' do
        assert_equal 3, ix_with_custom_program_index.program_index
      end
    end
  end
end

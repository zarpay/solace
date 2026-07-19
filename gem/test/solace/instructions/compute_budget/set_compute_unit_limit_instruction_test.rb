# frozen_string_literal: true

require 'test_helper'

describe Solace::Instructions::ComputeBudget::SetComputeUnitLimitInstruction do
  describe '.build' do
    # Build a set compute unit limit instruction
    let(:ix) do
      Solace::Instructions::ComputeBudget::SetComputeUnitLimitInstruction.build(
        units:         200_000,
        program_index: 1
      )
    end

    it 'returns an instruction' do
      assert_kind_of Solace::Instruction, ix
    end

    it 'sets the program index' do
      assert_equal 1, ix.program_index
    end

    it 'has no accounts' do
      assert_equal [], ix.accounts
    end

    it 'has the correct data' do
      assert_equal [2] + [200_000].pack('L<').bytes, ix.data
    end
  end
end

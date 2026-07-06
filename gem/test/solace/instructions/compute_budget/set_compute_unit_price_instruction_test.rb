# frozen_string_literal: true

require 'test_helper'

describe Solace::Instructions::ComputeBudget::SetComputeUnitPriceInstruction do
  describe '.build' do
    # Build a set compute unit price instruction
    let(:ix) do
      Solace::Instructions::ComputeBudget::SetComputeUnitPriceInstruction.build(
        micro_lamports: 50_000,
        program_index:  1
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
      assert_equal [3] + [50_000].pack('Q<').bytes, ix.data
    end
  end
end

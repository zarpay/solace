# frozen_string_literal: true
require_relative '../../test_helper'

describe Solana::Instructions::TransferInstruction do
  describe '.build' do
    before do
      @instruction = Solana::Instructions::TransferInstruction.build(
        lamports: 100_000,
        to_index: 0,
        from_index: 1
      )
    end

    it 'returns an instruction' do
      assert_kind_of Solana::Instruction, @instruction
    end

    it 'sets the default program index' do
      assert_equal 2, @instruction.program_index
    end

    it 'has the correct accounts' do
      assert_equal [1, 0], @instruction.accounts
    end

    it 'has the correct data' do
      assert_equal [2, 0, 0, 0] + [100_000].pack('Q<').bytes, @instruction.data
    end

    describe 'with custom program index' do
      before do
        @instruction = Solana::Instructions::TransferInstruction.build(
          lamports: 100_000,
          to_index: 0,
          from_index: 1,
          program_index: 3
        )
      end

      it 'sets the custom program index' do
        assert_equal 3, @instruction.program_index
      end
    end
  end
end
# frozen_string_literal: true
require_relative '../../test_helper'

describe Solana::Serializers::InstructionDeserializer do
  # Build a transfer instruction
  let(:ix) do
    Solana::Instructions::TransferInstruction.build(
      to_index: 1,
      from_index: 0,
      program_index: 2,
      lamports: 100_000_000,
    )
  end

  describe '#call' do
    before do
      @deserialized_ix = Solana::Serializers::InstructionDeserializer.call(ix.to_io)
    end

    it 'returns a deserialized instruction' do
      assert_kind_of Solana::Instruction, @deserialized_ix
    end

    it 'has the correct accounts' do
      assert_equal @deserialized_ix.accounts, [0, 1]
    end

    it 'has the correct program index' do
      assert_equal @deserialized_ix.program_index, 2
    end

    it 'has the correct data' do
      assert_equal @deserialized_ix.data, Solana::Instructions::TransferInstruction.data(100_000_000)
    end
  end
end

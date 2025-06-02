# frozen_string_literal: true
require_relative '../../test_helper'

describe Solana::Serializers::InstructionSerializer do
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
      @serialized_ix = Solana::Serializers::InstructionSerializer.call(ix)
    end

    it 'returns a serialized instruction' do
      assert_kind_of String, @serialized_ix
    end

    it 'has the correct structure' do
      assert_operator @serialized_ix.bytesize, :>, 0
    end
  end
end

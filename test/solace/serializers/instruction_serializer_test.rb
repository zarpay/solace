# frozen_string_literal: true

require_relative '../../test_helper'

describe Solace::Serializers::InstructionSerializer do
  # Build a transfer instruction
  let(:ix) do
    Solace::Instructions::TransferInstruction.build(
      to_index: 1,
      from_index: 0,
      program_index: 2,
      lamports: 100_000_000
    )
  end

  describe '#call' do
    before do
      @serialized_ix = Solace::Serializers::InstructionSerializer.call(ix)
    end

    it 'returns a serialized instruction' do
      assert_kind_of String, @serialized_ix
    end

    it 'has the correct structure' do
      assert_operator @serialized_ix.bytesize, :>, 0
    end
  end
end

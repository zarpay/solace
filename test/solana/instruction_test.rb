# frozen_string_literal: true
require_relative '../test_helper'


describe Solana::Instruction do
  let(:ix) { build(:instruction, :as_transfer) }

  describe '#serialize' do
    it 'returns a serialized instruction' do      
      assert_kind_of String, ix.serialize
    end

    it 'has the correct structure' do
      assert_operator ix.serialize.bytesize, :>, 0
    end
  end

  describe '#deserialize' do
    before do
      @deserialized_ix = Solana::Instruction.deserialize(ix.to_io)
    end

    it 'deserializes into the same instruction' do
      assert_equal @deserialized_ix.program_index, 2
      assert_equal @deserialized_ix.accounts, [0, 1]
      assert_equal @deserialized_ix.data, ix.data
    end
  end
end

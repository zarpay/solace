# frozen_string_literal: true
require_relative '../test_helper'


describe Solana::Instruction do
  before do
    @instruction_builder = Solana::Instructions::TransferInstruction
    # Build the instruction using a builder that will create a valid instruction
    @ix = @instruction_builder.build(
      lamports: 100_000,
      to_index: 0,
      from_index: 1,
      program_index: 2
    )
  end

  describe '#serialize' do
    it 'returns a serialized instruction' do      
      assert_kind_of String, @ix.serialize
    end
  end

  describe '#deserialize' do
    it 'deserializes into the same instruction' do
      @instruction = Solana::Instruction.deserialize(@ix.to_io)
      
      assert_equal @instruction.program_index, 2
      assert_equal @instruction.accounts, [1, 0]
      assert_equal @instruction.data, @instruction_builder.data(100_000)
    end
  end
end

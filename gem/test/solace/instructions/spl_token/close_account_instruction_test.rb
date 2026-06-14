# frozen_string_literal: true

require 'test_helper'

describe Solace::Instructions::SplToken::CloseAccountInstruction do
  describe 'build' do
    let(:account_index) { 0 }
    let(:destination_index) { 1 }
    let(:authority_index) { 2 }
    let(:program_index) { 3 }

    let(:ix) do
      Solace::Instructions::SplToken::CloseAccountInstruction.build(
        account_index:     account_index,
        destination_index: destination_index,
        authority_index:   authority_index,
        program_index:     program_index
      )
    end

    it 'should build a valid instruction' do
      assert_kind_of Solace::Instruction, ix
    end

    it 'should have the correct program index' do
      assert_equal program_index, ix.program_index
    end

    it 'should have the correct accounts' do
      assert_equal [account_index, destination_index, authority_index], ix.accounts
    end

    it 'should have the correct data' do
      assert_equal [9], ix.data
    end
  end
end

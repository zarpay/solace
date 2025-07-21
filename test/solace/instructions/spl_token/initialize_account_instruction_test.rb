# frozen_string_literal: true
require 'test_helper'

describe Solace::Instructions::SplToken::InitializeAccountInstruction do
  describe 'build' do    
    let(:account_index) { 0 }
    let(:mint_index) { 1 }
    let(:owner_index) { 2 }
    let(:rent_sysvar_index) { 3 }
    let(:program_index) { 4 }

    let(:ix) do
      Solace::Instructions::SplToken::InitializeAccountInstruction.build(
        account_index:,
        mint_index:,
        owner_index:,
        rent_sysvar_index:,
        program_index:,
      )
    end

    it 'should build a valid instruction' do
      assert_kind_of Solace::Instruction, ix
    end

    it 'should have the correct program index' do
      assert_equal program_index, ix.program_index
    end

    it 'should have the correct accounts' do
      assert_equal [account_index, mint_index, owner_index, rent_sysvar_index], ix.accounts
    end

    it 'should have the correct data' do
      assert_equal [1], ix.data
    end
  end
end
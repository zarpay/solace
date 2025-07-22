# frozen_string_literal: true

require 'test_helper'

describe Solace::Instructions::AssociatedTokenAccount::CreateAssociatedTokenAccountInstruction do
  describe '.build' do
    let(:mint) { Fixtures.load_keypair('mint') }
    let(:owner) { Fixtures.load_keypair('owner') }

    let(:ix) do
      Solace::Instructions::AssociatedTokenAccount::CreateAssociatedTokenAccountInstruction.build(
        mint: mint.address,
        owner: owner.address,
        from_index: 0,
        new_account_index: 1,
        associated_token_account_index: 2,
      )
    end

    it 'should build a valid instruction' do
      assert_kind_of Solace::Instruction, ix
    end

    it 'should have the correct program index' do
      assert_equal 2, ix.program_index
    end

    it 'should have the correct accounts' do
      assert_equal [0, 1, 2], ix.accounts
    end

    it 'should have the correct data' do
      assert_equal [0], ix.data
    end
  end
end

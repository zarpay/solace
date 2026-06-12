# frozen_string_literal: true

require 'test_helper'

describe Solace::Instructions::Token2022::HarvestWithheldTokensToMintInstruction do
  describe 'build' do
    let(:mint_index) { 0 }
    let(:source_index) { 1 }
    let(:program_index) { 2 }

    let(:ix) do
      Solace::Instructions::Token2022::HarvestWithheldTokensToMintInstruction.build(
        mint_index: mint_index,
        source_index: source_index,
        program_index: program_index
      )
    end

    it 'should build a valid instruction' do
      assert_kind_of Solace::Instruction, ix
    end

    it 'should have the correct program index' do
      assert_equal program_index, ix.program_index
    end

    it 'should have the correct accounts (mint then source, no signers)' do
      assert_equal [mint_index, source_index], ix.accounts
    end

    it 'should have the correct data (TransferFeeExtension -> HarvestWithheldTokensToMint)' do
      assert_equal [26, 4], ix.data
    end
  end
end

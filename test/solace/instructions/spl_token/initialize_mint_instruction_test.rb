# frozen_string_literal: true
require 'test_helper'

describe Solace::Instructions::SplToken::InitializeMintInstruction do
  describe 'build' do
    let(:decimals) { 6 }
    let(:mint_authority) { 'BvaC8MxEr1JQfoz4Ur4RybkcmL5QUKB57KjrvfL9DE64' }
    let(:freeze_authority) { nil }

    let(:mint_account_index) { 1 }
    let(:rent_sysvar_index) { 2 }
    let(:program_index) { 3 }

    let(:ix) do
      Solace::Instructions::SplToken::InitializeMintInstruction.build(
        decimals:,
        mint_authority:,
        freeze_authority:,
        mint_account_index:,
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
      assert_equal [mint_account_index, rent_sysvar_index], ix.accounts
    end

    describe 'with freeze authority' do
      let(:freeze_authority) { '8yfHvK7ZdcRQzjJ8KnT9xgceJbpiQjjuHcxqqHtdTNn6' }

      it 'should have the correct data' do
        assert_equal(
          [0, decimals] +
          Solace::Utils::Codecs.base58_to_bytes(mint_authority) +
          [1] +
          Solace::Utils::Codecs.base58_to_bytes(freeze_authority),
          ix.data
        )
      end
    end

    describe 'without freeze authority' do
      let(:freeze_authority) { nil }

      it 'should have the correct data' do
        assert_equal(
          [0, decimals] +
          Solace::Utils::Codecs.base58_to_bytes(mint_authority) +
          [0],
          ix.data
        )
      end
    end
  end
end
# frozen_string_literal: true

require 'test_helper'

describe Solace::Utils::ComputeBudget do
  let(:limit_composer) { Solace::Composers::ComputeBudgetProgramSetComputeUnitLimitComposer }
  let(:price_composer) { Solace::Composers::ComputeBudgetProgramSetComputeUnitPriceComposer }

  describe 'with nothing set' do
    let(:budget) { Solace::Utils::ComputeBudget.new }

    it 'is not set and translates to no composers' do
      refute_predicate budget, :set?
      assert_empty budget.composers
    end

    it 'supersedes no composer' do
      refute budget.supersedes?(limit_composer.new(units: 1))
      refute budget.supersedes?(price_composer.new(micro_lamports: 1))
    end
  end

  describe 'with both parts set' do
    let(:budget) { Solace::Utils::ComputeBudget.new(units: 200_000, micro_lamports: 50_000) }

    it 'translates to the limit composer then the price composer' do
      assert_predicate budget, :set?
      assert_equal [limit_composer, price_composer], budget.composers.map(&:class)
      assert_equal 200_000, budget.composers[0].units
      assert_equal 50_000, budget.composers[1].micro_lamports
    end

    it 'supersedes directly added ComputeBudget composers of either kind' do
      assert budget.supersedes?(limit_composer.new(units: 1))
      assert budget.supersedes?(price_composer.new(micro_lamports: 1))
      refute budget.supersedes?(Solace::Composers::SystemProgramTransferComposer.new(from: 'a', to: 'b', lamports: 1))
    end
  end

  describe 'with only the limit set' do
    let(:budget) { Solace::Utils::ComputeBudget.new(units: 200_000) }

    it 'translates to the limit composer alone' do
      assert_equal [limit_composer], budget.composers.map(&:class)
    end

    it 'supersedes only limit composers' do
      assert budget.supersedes?(limit_composer.new(units: 1))
      refute budget.supersedes?(price_composer.new(micro_lamports: 1))
    end
  end

  describe '#merge' do
    it 'takes the other budget where set and keeps its own otherwise' do
      merged = Solace::Utils::ComputeBudget.new(units: 100, micro_lamports: 1)
                                           .merge(Solace::Utils::ComputeBudget.new(units: 300))

      assert_equal 300, merged.units
      assert_equal 1, merged.micro_lamports
    end

    it 'takes the other budget where both set the same field' do
      merged = Solace::Utils::ComputeBudget.new(units: 100, micro_lamports: 1)
                                           .merge(Solace::Utils::ComputeBudget.new(units: 300, micro_lamports: 5))

      assert_equal 300, merged.units
      assert_equal 5, merged.micro_lamports
    end

    it 'keeps its own budget when the other is unset' do
      merged = Solace::Utils::ComputeBudget.new(units: 100, micro_lamports: 1).merge(Solace::Utils::ComputeBudget.new)

      assert_equal 100, merged.units
      assert_equal 1, merged.micro_lamports
    end

    it 'stays unset when both are unset' do
      refute_predicate Solace::Utils::ComputeBudget.new.merge(Solace::Utils::ComputeBudget.new), :set?
    end

    it 'answers a new budget, leaving both inputs alone' do
      original = Solace::Utils::ComputeBudget.new(units: 100)
      merged   = original.merge(Solace::Utils::ComputeBudget.new(micro_lamports: 5))

      refute_same original, merged
      assert_nil original.micro_lamports
    end
  end
end

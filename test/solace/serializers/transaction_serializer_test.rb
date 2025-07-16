# frozen_string_literal: true

require_relative '../../test_helper'

describe Solace::Serializers::TransactionSerializer do
  describe '#call' do
    describe 'legacy transaction' do
      let(:tx) { build(:transaction, :with_legacy_transfer) }

      before do
        @serialized_tx = Solace::Serializers::TransactionSerializer.call(tx)
      end

      it 'returns a valid binary string' do
        assert @serialized_tx.valid_encoding?
      end

      it 'has the correct structure' do
        assert_operator @serialized_tx.bytesize, :>, 0
      end
    end

    describe 'versioned transaction' do
      let(:tx) { build(:transaction, :with_versioned_transfer) }

      before do
        @serialized_tx = Solace::Serializers::TransactionSerializer.call(tx)
      end

      it 'returns a valid binary string' do
        assert @serialized_tx.valid_encoding?
      end

      it 'has the correct structure' do
        assert_operator @serialized_tx.bytesize, :>, 0
      end
    end
  end
end

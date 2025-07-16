# frozen_string_literal: true

require_relative '../../test_helper'

describe Solace::Serializers::MessageSerializer do
  describe '#call' do
    describe 'legacy message' do
      let(:msg) { build(:legacy_message, :with_transfer_instruction) }

      before do
        @serialized_msg = Solace::Serializers::MessageSerializer.call(msg)
      end

      it 'returns a valid binary string' do
        assert @serialized_msg.valid_encoding?
      end

      it 'has the correct structure' do
        assert_operator @serialized_msg.bytesize, :>, 0
      end

      it 'raises if blockhash is missing' do
        msg = build(:legacy_message, :with_transfer_instruction, recent_blockhash: nil)

        assert_raises(RuntimeError) do
          Solace::Serializers::MessageSerializer.call(msg)
        end
      end
    end

    describe 'versioned message' do
      let(:msg) { build(:versioned_message, :with_transfer_instruction) }

      before do
        @serialized_msg = Solace::Serializers::MessageSerializer.call(msg)
      end

      it 'returns a valid binary string' do
        assert @serialized_msg.valid_encoding?
      end

      it 'has the correct structure' do
        assert_operator @serialized_msg.bytesize, :>, 0
      end
    end
  end
end

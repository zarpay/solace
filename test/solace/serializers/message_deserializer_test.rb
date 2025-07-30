# frozen_string_literal: true

require_relative '../../test_helper'

describe Solace::Serializers::MessageDeserializer do
  describe '#call' do
    describe 'legacy message' do
      let(:msg) { build(:legacy_message, :with_transfer_instruction) }

      before do
        @msg = Solace::Serializers::MessageDeserializer.new(msg.to_io).call
      end

      it 'does not extract version' do
        refute @msg.versioned?
        assert_nil @msg.version
      end

      it 'extracts accounts' do
        assert_equal 3, @msg.accounts.size
      end

      it 'extracts instructions' do
        assert_equal 1, @msg.instructions.size
      end

      it 'extracts message header' do
        assert_equal [1, 0, 1], @msg.header
      end

      it 'extracts recent blockhash' do
        assert_kind_of String, @msg.recent_blockhash
      end
    end

    describe 'versioned message' do
      let(:msg) { build(:versioned_message, :with_transfer_instruction) }

      before do
        @msg = Solace::Serializers::MessageDeserializer.new(msg.to_io).call
      end

      it 'extracts version' do
        assert @msg.versioned?
        assert_equal 0, @msg.version
      end

      it 'extracts accounts' do
        assert_equal 3, @msg.accounts.size
      end

      it 'extracts instructions' do
        assert_equal 1, @msg.instructions.size
      end

      it 'extracts message header' do
        assert_equal [1, 0, 1], @msg.header
      end

      it 'extracts recent blockhash' do
        assert_kind_of String, @msg.recent_blockhash
      end

      it 'extracts address lookup table' do
        assert_equal 0, @msg.address_lookup_tables.size
      end
    end
  end
end

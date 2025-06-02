# frozen_string_literal: true
require_relative '../../test_helper'

describe Solana::Serializers::MessageDeserializer do
  describe '#call' do
    describe 'legacy message' do
      before do
        io = Solana::Transaction
          .deserialize('ATb9iy8YGDhu3n/lblX6vutFwL08V2vO6SWM0tzvXyYKfkl+JHJ+Ne3LQL2ST3bFz+yq8WKY6xRl1gT6Hl7OfwABAAEDFhf39JpMHlteXqQdhkKyBMHDjE/FI1nKB1VAYwoX8usJHpx5omCOgQLd62o8TZKcoP4rwMXr3VxZW7WY5RVdEQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAApnfy5i7sTd9C9sheZ1m39A4THe+MBUS0Mg0CR0ElXsIBAgIAAQwCAAAAQEIPAAAAAAA=')
          .message
          .to_io

        @msg = Solana::Serializers::MessageDeserializer.call(io)
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
      before do
        io = Solana::Transaction
          .deserialize('AWOGHsLk8vtOCVpO3U4nN0VhkzL5SaV+W9ChrclD0WuGFxYnT2RFc4nfmWNukLMmxNZGmE48b2rTpTlQ48VUvA+AAQABAxYX9/SaTB5bXl6kHYZCsgTBw4xPxSNZygdVQGMKF/LrCR6ceaJgjoEC3etqPE2SnKD+K8DF691cWVu1mOUVXREAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAALpuKeTKLDGR061cQispY/jwMv+wzUE4W1l7VC7UbqRjAQICAAEMAgAAAEBCDwAAAAAAAA==')
          .message
          .to_io

        @msg = Solana::Serializers::MessageDeserializer.call(io)
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

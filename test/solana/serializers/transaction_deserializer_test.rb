# frozen_string_literal: true
require_relative '../../test_helper'

describe Solana::Serializers::TransactionDeserializer do
  describe '#call' do
    describe 'legacy transaction' do
      before do
        @LEGACY_TX = 'ATb9iy8YGDhu3n/lblX6vutFwL08V2vO6SWM0tzvXyYKfkl+JHJ+Ne3LQL2ST3bFz+yq8WKY6xRl1gT6Hl7OfwABAAEDFhf39JpMHlteXqQdhkKyBMHDjE/FI1nKB1VAYwoX8usJHpx5omCOgQLd62o8TZKcoP4rwMXr3VxZW7WY5RVdEQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAApnfy5i7sTd9C9sheZ1m39A4THe+MBUS0Mg0CR0ElXsIBAgIAAQwCAAAAQEIPAAAAAAA='
        
        @tx = Solana::Serializers::TransactionDeserializer.call(@LEGACY_TX)
      end

      it 'extracts signatures' do
        assert_equal 1, @tx.signatures.size
      end

      it 'extracts message' do
        assert_kind_of Solana::Message, @tx.message
      end
    end
    
    describe 'versioned transaction' do
      before do
        @VERSIONED_TX = 'AWOGHsLk8vtOCVpO3U4nN0VhkzL5SaV+W9ChrclD0WuGFxYnT2RFc4nfmWNukLMmxNZGmE48b2rTpTlQ48VUvA+AAQABAxYX9/SaTB5bXl6kHYZCsgTBw4xPxSNZygdVQGMKF/LrCR6ceaJgjoEC3etqPE2SnKD+K8DF691cWVu1mOUVXREAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAALpuKeTKLDGR061cQispY/jwMv+wzUE4W1l7VC7UbqRjAQICAAEMAgAAAEBCDwAAAAAAAA=='
        
        @tx = Solana::Serializers::TransactionDeserializer.call(@VERSIONED_TX)
      end

      it 'extracts signatures' do
        assert_equal 1, @tx.signatures.size
      end

      it 'extracts message' do
        assert_kind_of Solana::Message, @tx.message
      end
    end
  end
end

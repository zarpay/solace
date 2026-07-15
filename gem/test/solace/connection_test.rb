# frozen_string_literal: true

require 'test_helper'

describe Solace::Connection do
  let(:connection) { Solace::Connection.new(commitment: 'processed') }

  describe '#get_block_height' do
    it 'returns the current block height' do
      assert_kind_of Integer, connection.get_block_height
    end

    it 'accepts a commitment override' do
      finalized = connection.get_block_height(commitment: 'finalized')
      processed = connection.get_block_height(commitment: 'processed')

      assert_operator finalized, :<=, processed
    end

    it 'stays at or below the last valid block height' do
      _blockhash, last_valid_block_height = connection.get_latest_blockhash

      assert_operator connection.get_block_height, :<=, last_valid_block_height
    end
  end

  describe '#get_slot' do
    it 'returns the current slot' do
      assert_kind_of Integer, connection.get_slot
    end

    it 'accepts a commitment override' do
      finalized = connection.get_slot(commitment: 'finalized')
      processed = connection.get_slot(commitment: 'processed')

      assert_operator finalized, :<=, processed
    end

    it 'stays at or above the block height' do
      assert_operator connection.get_slot, :>=, connection.get_block_height
    end
  end
end

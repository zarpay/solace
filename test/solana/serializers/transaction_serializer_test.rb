# frozen_string_literal: true
require_relative '../../test_helper'


describe Solana::Serializers::TransactionSerializer do
  describe '#call' do
    describe 'legacy transaction' do
      before do
        @msg = Solana::Message.new(
          header: [1, 0, 1],
          accounts: [
            '2VFAhjXBhMuEbmcTtjYXAZX4oVPhr3im7yb8RmaBofU6',
            'cbk37cQDdSqarxFTD9oG9c31YhcGZzd2QJwuGmWZhLL',
            Solana::Constants::SYSTEM_PROGRAM_ID
          ],
          recent_blockhash: '9s5BVd3xd3MinQcJbCCTBwXn6WRukcdEwgC2ZjktjKqu',
          instructions: [
            Solana::Instructions::TransferInstruction.build(
              to_index: 1,
              from_index: 0,
              program_index: 2,
              lamports: 1_000_000
            )
          ],
        )

        @tx = Solana::Transaction.new(message: @msg)

        @serialized_tx = Solana::Serializers::TransactionSerializer.call(@tx)
      end

      it 'returns a binary string' do
        assert @serialized_tx.valid_encoding?
        assert_kind_of String, @serialized_tx
      end

      it 'has the correct structure' do
        assert_operator @serialized_tx.bytesize, :>, 0
      end 
    end

    describe 'versioned transaction' do
      before do
        @msg = Solana::Message.new(
          version: 0,
          header: [1, 0, 1],
          accounts: [
            '2VFAhjXBhMuEbmcTtjYXAZX4oVPhr3im7yb8RmaBofU6',
            'cbk37cQDdSqarxFTD9oG9c31YhcGZzd2QJwuGmWZhLL',
            Solana::Constants::SYSTEM_PROGRAM_ID
          ],
          recent_blockhash: '9s5BVd3xd3MinQcJbCCTBwXn6WRukcdEwgC2ZjktjKqu',
          instructions: [
            Solana::Instructions::TransferInstruction.build(
              to_index: 1,
              from_index: 0,
              program_index: 2,
              lamports: 1_000_000
            )
          ],
          address_lookup_tables: []
        )

        @tx = Solana::Transaction.new(message: @msg)

        @serialized_tx = Solana::Serializers::TransactionSerializer.call(@tx)
      end

      it 'returns a binary string' do
        assert @serialized_tx.valid_encoding?
        assert_kind_of String, @serialized_tx
      end    
    end
  end
end

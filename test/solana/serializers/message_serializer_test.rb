# frozen_string_literal: true
require_relative '../../test_helper'


describe Solana::Serializers::MessageSerializer do
  describe '#call' do
    describe 'legacy message' do
      before do
        @msg = Solana::Message.new(
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

        @serialized_msg = Solana::Serializers::MessageSerializer.call(@msg)
      end

      it 'returns a binary string' do
        assert @serialized_msg.valid_encoding?
        assert_kind_of String, @serialized_msg
      end    

      it 'raises if blockhash is missing' do
        msg = Solana::Message.new(
          accounts: @msg.accounts,
          instructions: @msg.instructions,
          recent_blockhash: nil
        )

        assert_raises(RuntimeError) do
          Solana::Serializers::MessageSerializer.call(msg)
        end
      end

      it 'has the correct structure' do
        assert_operator @serialized_msg.bytesize, :>, 0
      end 
    end

    describe 'versioned message' do
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

        @serialized_msg = Solana::Serializers::MessageSerializer.call(@msg)
      end

      it 'returns a binary string' do
        assert @serialized_msg.valid_encoding?
        assert_kind_of String, @serialized_msg
      end    
    end
  end
end

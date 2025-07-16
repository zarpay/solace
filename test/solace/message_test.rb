# frozen_string_literal: true

require_relative '../test_helper'

describe Solace::Message do
  describe '#serialize' do
    before do
      @msg = Solace::Message.new(
        header: [1, 0, 1],
        accounts: [
          '2VFAhjXBhMuEbmcTtjYXAZX4oVPhr3im7yb8RmaBofU6',
          'cbk37cQDdSqarxFTD9oG9c31YhcGZzd2QJwuGmWZhLL',
          Solace::Constants::SYSTEM_PROGRAM_ID
        ],
        recent_blockhash: '9s5BVd3xd3MinQcJbCCTBwXn6WRukcdEwgC2ZjktjKqu',
        instructions: [
          Solace::Instructions::TransferInstruction.build(
            to_index: 1,
            from_index: 0,
            program_index: 2,
            lamports: 1_000_000
          )
        ]
      )
    end

    it 'returns serialized legacy message' do
      assert_kind_of String, @msg.serialize
    end

    it 'has the correct structure' do
      assert_operator @msg.serialize.bytesize, :>, 0
    end

    describe '#versioned?' do
      it 'returns false for legacy message' do
        @msg.version = nil

        refute @msg.versioned?
      end

      it 'returns true for versioned message' do
        @msg.version = 0

        assert @msg.versioned?
      end
    end
  end
end

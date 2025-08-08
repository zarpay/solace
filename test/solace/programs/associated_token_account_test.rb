# frozen_string_literal: true

require 'test_helper'

describe Solace::Programs::AssociatedTokenAccount do
  let(:klass) { Solace::Programs::AssociatedTokenAccount }
  let(:connection) { Solace::Connection.new }
  let(:program) { klass.new(connection: connection) }

  describe '#initialize' do
    it 'assigns connection' do
      assert_equal program.connection, connection
    end

    it 'assigns associated_token_account_program_id' do
      assert_equal program.program_id, Solace::Constants::ASSOCIATED_TOKEN_ACCOUNT_PROGRAM_ID
    end
  end

  describe '.get_or_create_address' do
    let(:owner) { Solace::Keypair.generate }
    let(:mint) { Fixtures.load_keypair('mint') }
    let(:payer) { Fixtures.load_keypair('payer') }

    let(:ata_address) { program.get_address(owner: owner, mint: mint).first }
    let(:address_result) { program.get_or_create_address(payer: payer, owner: owner, mint: mint) }

    describe "when the owner doesn't have a token account" do
      it 'creates a new token account at the expected address' do
        assert connection.get_balance(ata_address).zero?
        assert connection.get_balance(address_result)
        assert_equal address_result, ata_address
      end
    end

    describe 'when the owner already has a token account' do
      it 'returns the associated token account address' do
        # Doesn't send any create transaction to the cluster
        def connection.send_transaction(_)
          raise "send_transaction shouldn't be called when a token account already exists."
        end

        assert connection.get_balance(ata_address)
        assert connection.get_balance(address_result)
        assert_equal address_result, ata_address
      end
    end
  end
end

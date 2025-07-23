# frozen_string_literal: true

require 'test_helper'

describe Solace::Programs::SplToken do
  let(:klass) { Solace::Programs::SplToken }
  let(:connection) { Solace::Connection.new }
  let(:program) { klass.new(connection: connection) }
  
  describe '#initialize' do
    
    it 'assigns connection' do
      assert_equal program.connection, connection
    end

    it 'assigns program_id' do
      assert_equal program.program_id, Solace::Constants::TOKEN_PROGRAM_ID
    end
  end

  describe "create a token mint" do
    let(:decimals) { 6 }
    let(:payer) { Fixtures.load_keypair('payer') }
    
    let(:mint_keypair) { Solace::Keypair.generate }
    let(:mint_authority) { Solace::Keypair.generate }
    let(:freeze_authority) { Solace::Keypair.generate }
  
    describe '#prepare_create_mint' do

      let(:tx) do
        program.prepare_create_mint(
          payer:,
          decimals:,
          mint_keypair:,
          mint_authority:,
          freeze_authority:,
        )
      end  

      it 'should prepare a transaction' do
        assert_kind_of Solace::Transaction, tx
      end

      it 'should sign the transaction with the payer and mint authority' do
        assert_equal tx.signatures.length, 2

        # First account is payer
        assert_equal tx.message.accounts[0], payer.address

        # Second account is mint keypair
        assert_equal tx.message.accounts[1], mint_keypair.address 
      end

      it 'should set the correct header' do
        assert_equal tx.message.header, [2, 0, 3]
      end

      it 'should order the accounts correctly' do
        assert_equal(
          tx.message.accounts, 
          [
            payer.address,
            mint_keypair.address,
            Solace::Constants::SYSVAR_RENT_PROGRAM_ID,
            Solace::Constants::TOKEN_PROGRAM_ID,
            Solace::Constants::SYSTEM_PROGRAM_ID
          ]
        )
      end
      it 'should create two instructions (CreateAccountInstruction and InitializeMintInstruction)' do
        assert_equal tx.message.instructions.length, 2
      end
    end

    describe '#create_mint' do
      before(:all) do
        # 1. Create the mint and await confirmation
        connection.wait_for_confirmed_signature do
          response = program.create_mint(
            payer:,
            decimals:,
            mint_keypair:,
            mint_authority:,
            freeze_authority:,
          )

          response['result']
        end

        # 5. Get account info
        @account_info = connection.get_account_info(mint_keypair.address)
      end

      it 'account should not be executable' do
        assert_equal @account_info['executable'], false
      end

      it 'account should have 82 bytes of blockspace' do
        assert_equal @account_info['space'], 82
      end

      it 'account should be owned by the token program' do
        assert_equal @account_info['owner'], Solace::Constants::TOKEN_PROGRAM_ID
      end
    end
  end
end

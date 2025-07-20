# frozen_string_literal: true
require 'test_helper'

describe Solace::Instructions::SystemProgram::CreateAccountInstruction do
  describe 'build' do    
    let(:space) { 100 }
    let(:lamports) { 1000000000 }
    let(:owner) { Solace::Constants::SYSTEM_PROGRAM_ID }

    let(:ix) do
      Solace::Instructions::SystemProgram::CreateAccountInstruction.build(
        space:,
        lamports:,
        owner:,
        from_index: 0,
        new_account_index: 1,
        system_program_index: 2,
      )
    end

    it 'should build a valid instruction' do
      assert_kind_of Solace::Instruction, ix
    end

    it 'should have the correct program index' do
      assert_equal 2, ix.program_index
    end

    it 'should have the correct accounts' do
      assert_equal [0, 1], ix.accounts
    end

    it 'should have the correct data' do
      assert_equal( 
        [0, 0, 0, 0] + 
        [lamports].pack('Q<').bytes + 
        [space].pack('Q<').bytes + 
        Solace::Utils::Codecs.base58_to_bytes(owner), 
        ix.data
      )
    end
  end

  describe 'with custom program index' do
    let(:ix_with_custom_program_index) do
      Solace::Instructions::SystemProgram::CreateAccountInstruction.build(
        space: 100,
        lamports: 1000000000,
        owner: Solace::Constants::SYSTEM_PROGRAM_ID,
        from_index: 0,
        new_account_index: 1,
        system_program_index: 3,
      )
    end

    it 'should have the correct program index' do
      assert_equal 3, ix_with_custom_program_index.program_index
    end
  end

  describe 'account creation' do
    let(:conn) { Solace::Connection.new }

    let(:payer) { Fixtures.load_keypair('bob') }
    let(:new_account) { Solace::Keypair.generate }  

    let(:space) { 100 }
    let(:owner) { Solace::Constants::SYSTEM_PROGRAM_ID }
    let(:lamports) { conn.get_minimum_lamports_for_rent_exemption(space) }
    
   before(:all) do
      # 1. Build instruction
      instruction = Solace::Instructions::SystemProgram::CreateAccountInstruction.build(
        owner:,
        space:,
        lamports:,
        from_index: 0,
        new_account_index: 1,
        system_program_index: 2,
      )

      # 2. Build message
      message = Solace::Message.new(
        header: [
          2, # num_required_signatures
          0, # num_readonly_signed
          1  # num_readonly_unsigned
        ],
        accounts: [
          payer.address,
          new_account.address,
          Solace::Constants::SYSTEM_PROGRAM_ID
        ],
        recent_blockhash: conn.get_latest_blockhash,
        instructions: [instruction]
      )

      # 3. Build transaction
      transaction = Solace::Transaction.new(message: message)
      
      transaction.sign(payer, new_account)

      # 4. Send transaction
      conn.wait_for_confirmed_signature do
        response = conn.send_transaction(transaction.serialize)

        response['result']
      end

      # 5. Get account info
      @account_info = conn.get_account_info(new_account.address)
    end

    it 'account should not be executable' do
      assert_equal false, @account_info["executable"]
    end

    it 'account should have correct owner' do
      assert_equal owner, @account_info["owner"]
    end

    it 'account should have correct space' do
      assert_equal space, @account_info["space"]
    end

    it 'account should have correct lamports' do
      assert_equal lamports, @account_info["lamports"]
    end
  end
end
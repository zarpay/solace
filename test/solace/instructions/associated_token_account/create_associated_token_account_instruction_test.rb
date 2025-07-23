# frozen_string_literal: true

require 'test_helper'

describe Solace::Instructions::AssociatedTokenAccount::CreateAssociatedTokenAccountInstruction do
  describe '.build' do
    let(:ix) do
      Solace::Instructions::AssociatedTokenAccount::CreateAssociatedTokenAccountInstruction.build(
        funder_index: 0,
        associated_token_account_index: 1,
        owner_index: 2,
        mint_index: 3,
        system_program_index: 4,
        token_program_index: 5,
        program_index: 6
      )
    end

    it 'should build a valid instruction' do
      assert_kind_of Solace::Instruction, ix
    end

    it 'should have the correct program index' do
      assert_equal 6, ix.program_index
    end

    it 'should have the correct accounts' do
      assert_equal [0, 1, 2, 3, 4, 5], ix.accounts
    end

    it 'should have the correct data' do
      assert_equal [0], ix.data
    end
  end

  describe 'account creation' do
    let(:conn) { Solace::Connection.new }

    let(:mint) { Fixtures.load_keypair('mint') }
    let(:payer) { Fixtures.load_keypair('payer') }

    let(:owner) { Solace::Keypair.generate }

    before(:all) do
      # 1. Derive the Associated Token Account (ATA) address
      # This is a Program Derived Address (PDA), so we find it before creating it.
      ata_address, _ = Solace::Utils::PDA.find_program_address(
        [
          owner.address, 
          Solace::Constants::TOKEN_PROGRAM_ID,
          mint.address
        ],
        Solace::Constants::ASSOCIATED_TOKEN_ACCOUNT_PROGRAM_ID
      )

      # 2. Define the master list of accounts for the transaction in the correct order.
      # The instruction's account indices will refer to this list.
      accounts = [
        payer.address,          # 0: Funder (Payer), writable, signer
        ata_address,            # 1: New ATA, writable
        owner.address,          # 2: Owner, readonly
        mint.address,           # 3: Mint, readonly
        Solace::Constants::SYSTEM_PROGRAM_ID,                      # 4: System Program, readonly
        Solace::Constants::TOKEN_PROGRAM_ID,                   # 5: SPL Token Program, readonly
        Solace::Constants::ASSOCIATED_TOKEN_ACCOUNT_PROGRAM_ID # 6: The program we are calling
      ]

      # 3. Build the instruction, providing the index of each required account.
      instruction = Solace::Instructions::AssociatedTokenAccount::CreateAssociatedTokenAccountInstruction.build(
        funder_index: 0,
        associated_token_account_index: 1,
        owner_index: 2,
        mint_index: 3,
        system_program_index: 4,
        token_program_index: 5,
        program_index: 6
      )

      # 4. Build the message
      message = Solace::Message.new(
        header: [1, 0, 4], # 1 signer (payer), 4 readonly accounts
        accounts: accounts,
        recent_blockhash: conn.get_latest_blockhash,
        instructions: [instruction]
      )

      # 5. Build and sign the transaction
      tx = Solace::Transaction.new(message: message)
      tx.sign(payer)

      # 6. Send the transaction and verify success
      conn.wait_for_confirmed_signature do
        response = conn.send_transaction(tx.serialize)

        response['result']
      end

      # 7. Get account info
      @account_info = conn.get_account_info(ata_address)
    end

    it 'account should be owned by the token program' do
      assert_equal Solace::Constants::TOKEN_PROGRAM_ID, @account_info["owner"]
    end

    it 'account should have 165 bytes of blockspace' do
      assert_equal 165, @account_info["space"]
    end

    it 'account should not be executable' do
      assert_equal false, @account_info["executable"]
    end
  end
end

# frozen_string_literal: true

require 'test_helper'

describe Solace::Instructions::SplToken::TransferInstruction do
  let(:connection) { Solace::Connection.new }
  let(:spl_token_program) { Solace::Programs::SplToken.new(connection:) }
  let(:associated_token_account_program) { Solace::Programs::AssociatedTokenAccount.new(connection:) }

  let(:mint) { Fixtures.load_keypair('mint') }
  let(:mint_authority) { Fixtures.load_keypair('mint-authority') }

  let(:payer) { Fixtures.load_keypair('payer') }
  let(:source_owner) { Fixtures.load_keypair('bob') }
  let(:destination_owner) { Fixtures.load_keypair('anna') }

  let(:amount) { 1_000_000_000 }

  describe '.build' do
    let(:ix) do
      Solace::Instructions::SplToken::TransferInstruction.build(
        amount:,
        source_index: 1,
        destination_index: 2,
        owner_index: 0,
        program_index: 3
      )
    end

    it 'builds a valid instruction' do
      assert_kind_of Solace::Instruction, ix
    end

    it 'has the correct program index' do
      assert_equal 3, ix.program_index
    end

    it 'has the correct accounts' do
      assert_equal [1, 2, 0], ix.accounts
    end

    it 'has the correct data' do
      assert_equal Solace::Instructions::SplToken::TransferInstruction.data(amount), ix.data
    end
  end

  describe 'on-chain test' do
    let(:source) do
      ata_address, _ = Solace::Programs::AssociatedTokenAccount.get_address(owner: source_owner, mint:)
      ata_address
    end

    let(:destination) do
      ata_address, _ = Solace::Programs::AssociatedTokenAccount.get_address(owner: destination_owner, mint:)
      ata_address
    end

    before(:all) do
      # # Create ata for source and destination
      # @destination = associated_token_account_program.create_associated_token_account(owner: destination_owner, mint:, payer:)

      # Create mint, source ATA, and mint tokens
      connection.wait_for_confirmed_signature do
        spl_token_program.mint_to(
          payer:, 
          mint:,
          destination:,
          amount:,
          mint_authority:
        )['result']
      end

      # Accounts
      accounts = [
        payer.address,
        source_owner.address,
        source,
        destination,
        Solace::Constants::TOKEN_PROGRAM_ID
      ]

      # Instruction
      ix = Solace::Instructions::SplToken::TransferInstruction.build(
        amount:,
        source_index: 2,
        destination_index: 3,
        owner_index: 1,
        program_index: 4
      )

      # Message
      message = Solace::Message.new(
        header: [2, 0, 1],
        accounts:,
        instructions: [ix],
        recent_blockhash: connection.get_latest_blockhash,
      )

      # Transaction
      tx = Solace::Transaction.new(message:)
      tx.sign(payer, source_owner)

      # Send transaction
      connection.wait_for_confirmed_signature do
        @response = connection.send_transaction(tx.serialize)
        @response['result']
      end
    end

    it 'returns a valid signature' do
      assert_includes 84..88, @response['result'].length
    end
  end
end
# frozen_string_literal: true

require 'test_helper'

describe Solace::Instructions::SplToken::MintToInstruction do
  let(:connection) { Solace::Connection.new }

  describe '.build' do
    let(:ix) do
      Solace::Instructions::SplToken::MintToInstruction.build(
        amount: 1_000_000,
        mint_authority_index: 0,
        mint_index: 1,
        destination_index: 2,
        program_index: 3
      )
    end

    it 'should build a valid instruction' do
      assert_kind_of Solace::Instruction, ix
    end

    it 'should have the correct program index' do
      assert_equal 3, ix.program_index
    end

    it 'should have the correct accounts' do
      assert_equal [1, 2, 0], ix.accounts
    end

    it 'should have the correct data' do
      # 7 is the instruction index for mint_to
      # 1_000_000 is the amount in little-endian format
      assert_equal [7] + Solace::Utils::Codecs.encode_le_u64(1_000_000).bytes, ix.data
    end
  end

  describe 'on-chain test' do
    let(:owner) { Fixtures.load_keypair('bob') }
    let(:mint) { Fixtures.load_keypair('mint') }
    let(:payer) { Fixtures.load_keypair('payer') }
    let(:mint_authority) { Fixtures.load_keypair('mint-authority') }

    let(:amount) { 1_000_000_000 }

    before(:all) do
      # We need a token account to mint to, so we'll use the Associated Token Account program
      # to create one for the owner.
      ata_program = Solace::Programs::AssociatedTokenAccount.new(connection: connection)

      # Get the associated token account address
      @ata_address, = ata_program.get_address(owner: owner, mint: mint)

      accounts = [
        payer.address,
        mint_authority.address,
        mint.address,
        @ata_address,
        Solace::Constants::TOKEN_PROGRAM_ID
      ]

      # Now, mint to the newly created associated token account
      ix = Solace::Instructions::SplToken::MintToInstruction.build(
        amount: amount,
        mint_authority_index: 1,
        mint_index: 2,
        destination_index: 3,
        program_index: 4
      )

      message = Solace::Message.new(
        header: [
          2, # num_required_signatures
          0, # num_readonly_signed
          1  # num_readonly_unsigned
        ],
        accounts: accounts,
        instructions: [ix],
        recent_blockhash: connection.get_latest_blockhash[0]
      )

      tx = Solace::Transaction.new(message: message)
      tx.sign(payer, mint_authority)

      # Send the transaction
      connection.wait_for_confirmed_signature do
        connection.send_transaction(tx.serialize)['result']
      end
    end

    it 'should have the correct token balance' do
      # TODO: fix this test to use a get token balance call
      balance = connection.get_account_info(@ata_address)

      data_binary = Base64.decode64(balance.dig('data', 0))
      amount_slice = data_binary.slice(64, 8)
      token_balance = amount_slice.unpack1('Q<')

      assert_operator amount, :<=, token_balance
    end
  end
end

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

  describe 'create a token mint' do
    let(:decimals) { 6 }
    let(:payer) { Fixtures.load_keypair('payer') }

    let(:mint_keypair) { Solace::Keypair.generate }
    let(:mint_authority) { Solace::Keypair.generate }
    let(:freeze_authority) { Solace::Keypair.generate }

    describe '#prepare_create_mint' do
      let(:tx) do
        program.prepare_create_mint(
          payer: payer,
          decimals: decimals,
          mint_keypair: mint_keypair,
          mint_authority: mint_authority,
          freeze_authority: freeze_authority
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
            payer: payer,
            decimals: decimals,
            mint_keypair: mint_keypair,
            mint_authority: mint_authority,
            freeze_authority: freeze_authority
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

  describe 'mint tokens' do
    let(:amount) { 1_000_000 }

    let(:mint) { Fixtures.load_keypair('mint') }
    let(:owner) { Fixtures.load_keypair('bob') }
    let(:payer) { Fixtures.load_keypair('payer') }
    let(:mint_authority) { Fixtures.load_keypair('mint-authority') }

    let(:destination) do
      ata_address, = Solace::Programs::AssociatedTokenAccount.get_address(owner: owner, mint: mint)
      ata_address
    end

    describe '#prepare_mint_to' do
      let(:tx) do
        program.prepare_mint_to(
          amount: amount,
          mint: mint,
          payer: payer,
          destination: destination,
          mint_authority: mint_authority
        )
      end

      it 'should prepare a transaction' do
        assert_kind_of Solace::Transaction, tx
      end

      describe 'when the mint authority is not the payer' do
        it 'should sign the transaction with the payer and mint authority' do
          assert_equal tx.signatures.length, 2
          assert_equal tx.message.accounts[0], payer.address
          assert_equal tx.message.accounts[1], mint_authority.address
        end
      end

      describe 'when the mint authority is the payer' do
        let(:mint_authority) { payer }

        it 'should sign the transaction with the payer' do
          assert_equal tx.signatures.length, 1
          assert_equal tx.message.accounts[0], payer.address
        end
      end
    end

    describe '#mint_to' do
      before(:all) do
        connection.wait_for_confirmed_signature do
          @result = program.mint_to(
            amount: amount,
            mint: mint,
            payer: payer,
            destination: destination,
            mint_authority: mint_authority
          )

          @result['result']
        end
      end

      it 'should return a valid signature' do
        assert_includes 84..88, @result['result'].length
      end
    end
  end

  describe 'transfer tokens' do
    let(:amount) { 1_000_000 }

    let(:payer) { Fixtures.load_keypair('payer') }
    let(:source_owner) { Fixtures.load_keypair('bob') }
    let(:destination_owner) { Fixtures.load_keypair('anna') }

    let(:mint) { Fixtures.load_keypair('mint') }
    let(:mint_authority) { Fixtures.load_keypair('mint-authority') }

    let(:source) { Solace::Programs::AssociatedTokenAccount.get_address(owner: source_owner, mint: mint).first }
    let(:destination) { Solace::Programs::AssociatedTokenAccount.get_address(owner: destination_owner, mint: mint).first }

    describe '#prepare_transfer' do
      let(:tx) do
        program.prepare_transfer(
          amount: amount,
          payer: payer,
          source: source,
          destination: destination,
          owner: source_owner
        )
      end

      it 'should prepare a transaction' do
        assert_kind_of Solace::Transaction, tx
      end
    end

    describe '#transfer' do
      before(:all) do
        @response = program.transfer(
          amount: amount,
          payer: payer,
          source: source,
          owner: source_owner,
          destination: destination
        )

        connection.wait_for_confirmed_signature { @response['result'] }
      end

      it 'should return a valid signature' do
        assert_includes 84..88, @response['result'].length
      end
    end
  end
end

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
    let(:address_result) { program.get_or_create_address(payer: payer, funder: payer, owner: owner, mint: mint) }

    describe "when the owner doesn't have a token account" do
      it 'creates a new token account at the expected address' do
        assert connection.get_balance(ata_address).zero?
        assert connection.get_balance(address_result)
        assert_equal address_result, ata_address
      end
    end

    describe 'when the owner already has a token account' do
      it 'returns the associated token account address' do
        # Create the token account
        assert connection.get_balance(address_result)

        # Doesn't send any create transaction to the cluster
        def connection.send_transaction(_)
          raise "send_transaction shouldn't be called when a token account already exists."
        end

        # The token account should still exist
        assert connection.get_balance(address_result)
      end
    end
  end

  describe '#get_address' do
    let(:owner) { Solace::Keypair.generate }
    let(:mint) { Fixtures.load_keypair('mint') }

    it 'returns the expected associated token account address' do
      ata_address, _bump = program.get_address(owner: owner, mint: mint)

      expected_ata_address, _expected_bump = Solace::Utils::PDA.find_program_address(
        [
          owner.to_s,
          Solace::Constants::TOKEN_PROGRAM_ID,
          mint.to_s
        ],
        Solace::Constants::ASSOCIATED_TOKEN_ACCOUNT_PROGRAM_ID
      )

      assert_equal ata_address, expected_ata_address
    end

    describe 'with a Token-2022 token_program_id override' do
      # PYUSD on Solana is a Token-2022 mint; these values are real and serve as
      # a regression fixture against accidentally re-baking the legacy program
      # ID into the ATA derivation.
      let(:pyusd_owner)   { '2d3FDocHuJSMUYc9A67hT4qEnmZMdUVem8aRgQ3S7KLG' }
      let(:pyusd_mint)    { '2b1kV6DkPAnxd5ixfnxCpjxmKwqjjaYmCZfHsFu24GXo' }
      let(:legacy_ata)    { 'AiAz6n4Z3ba9jrkiQQ42HyeWjM1HogSoZtMkatt3KdHQ' }
      let(:token_2022_ata) { '21tgPUvQBJxuvHwPcKP1DxXSKaQpQ4s3bRverkfDEq7D' }

      it 'derives the Token-2022 ATA address when the program id is provided' do
        ata, _bump = klass.get_address(
          owner:            pyusd_owner,
          mint:             pyusd_mint,
          token_program_id: Solace::Constants::TOKEN_2022_PROGRAM_ID
        )

        assert_equal token_2022_ata, ata
      end

      it 'derives the legacy SPL ATA when no program id is provided' do
        ata, _bump = klass.get_address(owner: pyusd_owner, mint: pyusd_mint)

        assert_equal legacy_ata, ata
      end

      it 'derives different addresses for the two programs' do
        legacy, = klass.get_address(owner: pyusd_owner, mint: pyusd_mint)
        t22,    = klass.get_address(
          owner:            pyusd_owner,
          mint:             pyusd_mint,
          token_program_id: Solace::Constants::TOKEN_2022_PROGRAM_ID
        )

        refute_equal legacy, t22
      end
    end
  end

  describe '#get_or_create_address' do
    let(:owner) { Solace::Keypair.generate }

    let(:bob) { Fixtures.load_keypair('bob') }
    let(:mint) { Fixtures.load_keypair('mint') }
    let(:payer) { Fixtures.load_keypair('payer') }

    it 'creates the rent exempt associated token account' do
      ata_address = program.get_or_create_address(
        payer:  payer,
        funder: payer,
        owner:  owner,
        mint:   mint
      )

      assert connection.get_balance(ata_address).positive?
    end

    it 'does not create a new associated token account if one already exists' do
      def connection.send_transaction
        raise("send_transaction shouldn't be called")
      end

      ata_address = program.get_or_create_address(
        payer:  payer,
        funder: payer,
        owner:  bob,
        mint:   mint
      )

      assert ata_address.is_a?(String)
    end
  end

  describe 'creating an associated token account' do
    let(:owner) { Solace::Keypair.generate }

    let(:mint) { Fixtures.load_keypair('mint') }
    let(:payer) { Fixtures.load_keypair('payer') }

    let(:ata_address) { program.get_address(owner: owner, mint: mint).first }

    describe '#compose_create_associated_token_account' do
      let(:composer) do
        program.compose_create_associated_token_account(
          owner:  owner,
          mint:   mint,
          funder: payer
        )
      end

      it 'composes a create associated token account instruction' do
        assert_kind_of Solace::Composers::AssociatedTokenAccountProgramCreateAccountComposer, composer.instruction_composers.first
      end
    end

    describe '#create_associated_token_account' do
      it 'creates and sends the associated token account creation transaction' do
        tx = program.create_associated_token_account(
          payer:  payer,
          owner:  owner,
          mint:   mint,
          funder: payer
        )

        connection.wait_for_confirmed_signature { tx.signature }

        assert_equal connection.get_token_account_balance(ata_address)['uiAmount'], 0.0
      end

      it 'creates but does not sign the transaction' do
        tx = program.create_associated_token_account(
          payer:  payer,
          sign:   false,
          owner:  owner,
          mint:   mint,
          funder: payer
        )

        assert_equal tx.signatures.count, 0
      end

      it 'creates but does not send the transaction' do
        tx = program.create_associated_token_account(
          payer:   payer,
          execute: false,
          owner:   owner,
          mint:    mint,
          funder:  payer
        )

        assert tx.signature.is_a?(String)
        assert_equal connection.get_signature_status(tx.signature)['value'], [nil]
      end

      it 'yeilds the composer for customization' do
        yielded = false

        program.create_associated_token_account(
          payer:   payer,
          execute: false,
          owner:   owner,
          mint:    mint,
          funder:  payer
        ) do |composer|
          yielded = true
          assert_kind_of Solace::Composers::AssociatedTokenAccountProgramCreateAccountComposer, composer.instruction_composers.first
        end

        assert yielded
      end
    end
  end
end

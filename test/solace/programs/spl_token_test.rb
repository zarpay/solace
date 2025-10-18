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

    let(:mint_account) { Solace::Keypair.generate }
    let(:mint_authority) { Solace::Keypair.generate }
    let(:freeze_authority) { Solace::Keypair.generate }

    describe 'the payer is the funder' do
      describe '#compose_create_mint' do
        let(:composer) do
          program.compose_create_mint(
            funder: payer,
            decimals: decimals,
            mint_account: mint_account,
            mint_authority: mint_authority,
            freeze_authority: freeze_authority
          )
        end

        it 'should prepare the correct instruction composers' do
          assert_kind_of Solace::Composers::SystemProgramCreateAccountComposer, composer.instruction_composers.first
          assert_kind_of Solace::Composers::SplTokenProgramInitializeMintComposer, composer.instruction_composers.last
        end
      end

      describe '#create_mint' do
        it 'should return a valid signature and create the mint account' do
          # Create the mint
          tx = program.create_mint(
            payer: payer,
            funder: payer,
            decimals: decimals,
            mint_account: mint_account,
            mint_authority: mint_authority,
            freeze_authority: freeze_authority
          )

          connection.wait_for_confirmed_signature { tx.signature }

          # Get account info
          account_info = connection.get_account_info(mint_account.address)

          assert_equal account_info['space'], 82
          assert_equal account_info['executable'], false
          assert_equal account_info['owner'], Solace::Constants::TOKEN_PROGRAM_ID
        end

        it 'should prepare a transaction without signing it' do
          tx = program.create_mint(
            payer: payer,
            funder: payer,
            sign: false,
            decimals: decimals,
            mint_account: mint_account,
            mint_authority: mint_authority,
            freeze_authority: freeze_authority
          )

          assert_equal tx.signatures.count, 0
        end

        it 'should prepare a transaction without sending it' do
          tx = program.create_mint(
            payer: payer,
            funder: payer,
            execute: false,
            decimals: decimals,
            mint_account: mint_account,
            mint_authority: mint_authority,
            freeze_authority: freeze_authority
          )

          # Assert the signature exists but the transaction was not sent
          assert tx.signature.is_a?(String)
          assert_equal connection.get_signature_status(tx.signature)['value'], [nil]
        end

        it 'should yield the composer to the block' do
          yielded = false

          program.create_mint(
            payer: payer,
            funder: payer,
            execute: false,
            decimals: decimals,
            mint_account: mint_account,
            mint_authority: mint_authority,
            freeze_authority: freeze_authority
          ) do |composer|
            yielded = true
            assert_kind_of Solace::TransactionComposer, composer
          end

          assert yielded
        end

        describe 'the payer is not the funder' do
          let(:funder) { Fixtures.load_keypair('bob') }

          it 'should return a valid signature and create the mint account' do
            # Create the mint
            tx = program.create_mint(
              payer: payer,
              funder: funder,
              decimals: decimals,
              mint_account: mint_account,
              mint_authority: mint_authority,
              freeze_authority: freeze_authority
            )

            connection.wait_for_confirmed_signature { tx.signature }

            # Get account info
            account_info = connection.get_account_info(mint_account.address)

            assert_equal account_info['space'], 82
            assert_equal account_info['executable'], false
            assert_equal account_info['owner'], Solace::Constants::TOKEN_PROGRAM_ID
          end
        end
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

    describe '#compose_mint_to' do
      let(:composer) do
        program.compose_mint_to(
          amount: amount,
          mint: mint,
          destination: destination,
          mint_authority: mint_authority
        )
      end

      it 'should prepare the correct instruction composer' do
        assert_kind_of Solace::Composers::SplTokenProgramMintToComposer, composer.instruction_composers.first
      end
    end

    describe '#mint_to' do
      it 'should return a valid signature and mint tokens to the destination account' do
        # Get starting balance
        account_starting_balance = connection.get_token_account_balance(destination)['amount'].to_i

        # Mint tokens
        tx = program.mint_to(
          amount: amount,
          mint: mint,
          payer: payer,
          destination: destination,
          mint_authority: mint_authority
        )

        connection.wait_for_confirmed_signature { tx.signature }

        # Final balance
        account_info = connection.get_token_account_balance(destination)

        assert_equal account_info['amount'].to_i, amount + account_starting_balance
      end

      it 'should prepare a transaction without signing it' do
        tx = program.mint_to(
          amount: amount,
          mint: mint,
          payer: payer,
          destination: destination,
          mint_authority: mint_authority,
          sign: false
        )

        assert_equal tx.signatures.count, 0
      end

      it 'should prepare a transaction without sending it' do
        tx = program.mint_to(
          amount: amount,
          mint: mint,
          payer: payer,
          destination: destination,
          mint_authority: mint_authority,
          execute: false
        )

        # Assert the signature exists but the transaction was not sent
        assert tx.signature.is_a?(String)
        assert_equal connection.get_signature_status(tx.signature)['value'], [nil]
      end

      it 'should yield the composer to the block' do
        yielded = false

        program.mint_to(
          amount: amount,
          mint: mint,
          payer: payer,
          destination: destination,
          mint_authority: mint_authority,
          execute: false
        ) do |composer|
          yielded = true
          assert_kind_of Solace::TransactionComposer, composer
        end

        assert yielded
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

    describe '#compose_transfer' do
      let(:composer) do
        program.compose_transfer(
          amount: amount,
          source: source,
          owner: source_owner,
          destination: destination
        )
      end

      it 'should prepare the correct instruction composer' do
        assert_kind_of Solace::Composers::SplTokenProgramTransferComposer, composer.instruction_composers.first
      end
    end

    describe '#transfer' do
      it 'should return a valid signature and transfer tokens between accounts' do
        # Get initial balances
        source_initial_balance = connection.get_token_account_balance(source)['amount'].to_i
        destination_initial_balance = connection.get_token_account_balance(destination)['amount'].to_i

        # Transfer tokens
        tx = program.transfer(
          amount: amount,
          payer: payer,
          source: source,
          owner: source_owner,
          destination: destination
        )

        connection.wait_for_confirmed_signature { tx.signature }

        # Final balances
        source_final_balance      = connection.get_token_account_balance(source)['amount'].to_i
        destination_final_balance = connection.get_token_account_balance(destination)['amount'].to_i

        assert_equal source_final_balance, source_initial_balance - amount
        assert_equal destination_final_balance, destination_initial_balance + amount
      end

      it 'should prepare a transaction without signing it' do
        tx = program.transfer(
          amount: amount,
          payer: payer,
          source: source,
          owner: source_owner,
          destination: destination,
          sign: false
        )

        assert_equal tx.signatures.count, 0
      end

      it 'should prepare a transaction without sending it' do
        tx = program.transfer(
          amount: amount,
          payer: payer,
          source: source,
          owner: source_owner,
          destination: destination,
          execute: false
        )

        # Assert the signature exists but the transaction was not sent
        assert tx.signature.is_a?(String)
        assert_equal connection.get_signature_status(tx.signature)['value'], [nil]
      end

      it 'should yield the composer to the block' do
        yielded = false

        program.transfer(
          amount: amount,
          payer: payer,
          source: source,
          owner: source_owner,
          destination: destination,
          execute: false
        ) do |composer|
          yielded = true
          assert_kind_of Solace::TransactionComposer, composer
        end

        assert yielded
      end
    end
  end

  describe 'transfer tokens with checks' do
    let(:amount) { 1_000_000 }

    let(:payer) { Fixtures.load_keypair('payer') }
    let(:source_owner) { Fixtures.load_keypair('bob') }
    let(:destination_owner) { Fixtures.load_keypair('anna') }

    let(:decimals) { 6 }
    let(:mint) { Fixtures.load_keypair('mint') }
    let(:mint_authority) { Fixtures.load_keypair('mint-authority') }

    let(:source) { Solace::Programs::AssociatedTokenAccount.get_address(owner: source_owner, mint: mint).first }
    let(:destination) { Solace::Programs::AssociatedTokenAccount.get_address(owner: destination_owner, mint: mint).first }

    describe '#compose_transfer_checked' do
      let(:composer) do
        program.compose_transfer_checked(
          amount: amount,
          decimals: decimals,
          to: destination,
          authority: source_owner,
          from: source,
          mint: mint
        )
      end

      it 'should prepare the correct instruction composer' do
        assert_kind_of Solace::Composers::SplTokenProgramTransferCheckedComposer, composer.instruction_composers.first
      end
    end

    describe '#transfer_checked' do
      it 'should return a valid signature and transfer tokens between accounts' do
        # Get initial balances
        source_initial_balance      = connection.get_token_account_balance(source)['amount'].to_i
        destination_initial_balance = connection.get_token_account_balance(destination)['amount'].to_i

        # Transfer tokens
        tx = program.transfer_checked(
          payer: payer,
          amount: amount,
          decimals: decimals,
          to: destination,
          authority: source_owner,
          from: source,
          mint: mint
        )

        connection.wait_for_confirmed_signature { tx.signature }

        # Final balances
        source_final_balance      = connection.get_token_account_balance(source)['amount'].to_i
        destination_final_balance = connection.get_token_account_balance(destination)['amount'].to_i

        assert_equal source_final_balance, source_initial_balance - amount
        assert_equal destination_final_balance, destination_initial_balance + amount
      end

      it 'should prepare a transaction without signing it' do
        tx = program.transfer_checked(
          payer: payer,
          sign: false,
          amount: amount,
          decimals: decimals,
          to: destination,
          authority: source_owner,
          from: source,
          mint: mint
        )

        assert_equal tx.signatures.count, 0
      end

      it 'should prepare a transaction without sending it' do
        tx = program.transfer_checked(
          payer: payer,
          execute: false,
          amount: amount,
          decimals: decimals,
          to: destination,
          authority: source_owner,
          from: source,
          mint: mint
        )

        # Assert the signature exists but the transaction was not sent
        assert tx.signature.is_a?(String)
        assert_equal connection.get_signature_status(tx.signature)['value'], [nil]
      end

      it 'should yield the composer to the block' do
        yielded = false

        program.transfer_checked(
          payer: payer,
          execute: false,
          amount: amount,
          decimals: decimals,
          to: destination,
          authority: source_owner,
          from: source,
          mint: mint
        ) do |composer|
          yielded = true
          assert_kind_of Solace::TransactionComposer, composer
        end

        assert yielded
      end
    end
  end

  describe 'chaining composers' do
    # In this example, we will create a mint, create an associated token account,
    # and mint tokens to that account in a single transaction. This demonstrates how
    # multiple instruction composers can be chained together using the TransactionComposer.
    let(:decimals) { 9 }
    let(:amount) { 1_000_000_000 }

    let(:payer) { Fixtures.load_keypair('payer') }
    let(:mint_account) { Solace::Keypair.generate }
    let(:mint_authority) { Solace::Keypair.generate }

    let(:owner) { Fixtures.load_keypair('bob') }

    it 'should create a mint, associated token account, and mint tokens in one transaction' do
      # Get the associated token account address (we will only use this for looking up the balance)
      ata_address, = Solace::Programs::AssociatedTokenAccount.get_address(owner: owner, mint: mint_account)

      # Compose the create mint instruction
      create_mint_composer = program.compose_create_mint(
        funder: payer,
        decimals: decimals,
        mint_account: mint_account,
        mint_authority: mint_authority
      )

      # Compose the create associated token account instruction
      ata_program = Solace::Programs::AssociatedTokenAccount.new(connection: connection)

      create_ata_composer = ata_program.compose_create_associated_token_account(
        funder: payer,
        owner: owner,
        mint: mint_account
      )

      # Compose the mint to instruction
      mint_to_composer = program.compose_mint_to(
        amount: 1_000_000_000,
        mint: mint_account,
        destination: ata_address,
        mint_authority: mint_authority
      )

      # The merge methods allow us to control the order of instructions
      # by specifying placement options while combining composers.
      tx = create_mint_composer
           .merge(create_ata_composer)
           .merge(mint_to_composer)
           .set_fee_payer(payer)
           .compose_transaction

      tx.sign(payer, mint_authority, mint_account)

      # Get the starting balance
      starting_balance = connection.get_account_info(ata_address)

      # Send the transaction
      response = connection.send_transaction(tx.serialize)
      connection.wait_for_confirmed_signature { response['result'] }

      # Verify the token balance
      ending_balance = connection.get_token_account_balance(ata_address)

      assert_nil starting_balance
      assert_equal ending_balance['amount'].to_i, 1_000_000_000
    end
  end
end

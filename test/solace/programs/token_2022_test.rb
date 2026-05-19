# frozen_string_literal: true

require 'test_helper'

# Pure-unit tests for the Token-2022 program client. The base instruction
# surface (Transfer, TransferChecked, MintTo, InitializeMint, CloseAccount)
# is shared in shape with the legacy SPL Token program but each Token-2022
# composer is its own class, bound to TOKEN_2022_PROGRAM_ID. These tests
# verify the wiring — that Token2022 reaches the right composer class.
describe Solace::Programs::Token2022 do
  let(:klass) { Solace::Programs::Token2022 }
  let(:connection) { Solace::Connection.new }
  let(:program) { klass.new(connection: connection) }

  describe '#initialize' do
    it 'assigns connection' do
      assert_equal program.connection, connection
    end

    it 'assigns the Token-2022 program id' do
      assert_equal program.program_id, Solace::Constants::TOKEN_2022_PROGRAM_ID
    end

    it 'mixes in the shared TokenProgramInterface' do
      assert_includes klass.included_modules, Solace::Programs::TokenProgramInterface
    end
  end

  describe '#compose_transfer' do
    let(:source)      { Solace::Keypair.generate }
    let(:destination) { Solace::Keypair.generate }
    let(:owner)       { Solace::Keypair.generate }

    let(:composer) do
      program.compose_transfer(
        amount: 1_000,
        source: source,
        destination: destination,
        owner: owner
      )
    end

    let(:transfer_ix) { composer.instruction_composers.first }

    it 'builds a Token2022ProgramTransferComposer' do
      assert_kind_of Solace::Composers::Token2022ProgramTransferComposer, transfer_ix
    end

    it 'binds the composer to the Token-2022 program id' do
      assert_equal Solace::Constants::TOKEN_2022_PROGRAM_ID, transfer_ix.token_2022_program
    end
  end

  describe '#compose_create_mint' do
    let(:funder)         { Solace::Keypair.generate }
    let(:mint_account)   { Solace::Keypair.generate }
    let(:mint_authority) { Solace::Keypair.generate }

    # compose_create_mint calls connection.get_minimum_lamports_for_rent_exemption,
    # so we stub the connection rather than requiring a live validator.
    before do
      def connection.get_minimum_lamports_for_rent_exemption(_space)
        1_461_600
      end
    end

    let(:composer) do
      program.compose_create_mint(
        funder: funder,
        decimals: 6,
        mint_account: mint_account,
        mint_authority: mint_authority
      )
    end

    let(:init_mint_ix) { composer.instruction_composers.last }

    it 'builds a Token2022ProgramInitializeMintComposer' do
      assert_kind_of Solace::Composers::Token2022ProgramInitializeMintComposer, init_mint_ix
    end

    it 'binds the initialize-mint composer to the Token-2022 program id' do
      assert_equal Solace::Constants::TOKEN_2022_PROGRAM_ID, init_mint_ix.token_2022_program
    end

    it 'sets the new mint account owner to the Token-2022 program' do
      create_account_ix = composer.instruction_composers.first

      assert_kind_of Solace::Composers::SystemProgramCreateAccountComposer, create_account_ix
      assert_equal program.program_id, create_account_ix.params[:owner]
    end
  end
end

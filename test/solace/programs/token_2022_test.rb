# frozen_string_literal: true

require 'test_helper'

# Pure-unit tests for the Token-2022 program client. Integration tests against
# a Token-2022 mint live in spl_token_test.rb (shared validator setup); the
# tests here verify the wiring — that Token2022 reaches the shared
# TokenProgramBase methods with the right program id baked into each composer.
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

    it 'inherits the shared TokenProgramBase implementation' do
      assert_kind_of Solace::Programs::TokenProgramBase, program
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

    it 'builds an SplTokenProgramTransferComposer' do
      assert_kind_of Solace::Composers::SplTokenProgramTransferComposer, transfer_ix
    end

    it 'threads the Token-2022 program id into the composer' do
      assert_equal Solace::Constants::TOKEN_2022_PROGRAM_ID, transfer_ix.spl_token_program
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

    it 'builds an SplTokenProgramInitializeMintComposer' do
      assert_kind_of Solace::Composers::SplTokenProgramInitializeMintComposer, init_mint_ix
    end

    it 'threads the Token-2022 program id into the initialize-mint instruction' do
      assert_equal Solace::Constants::TOKEN_2022_PROGRAM_ID, init_mint_ix.spl_token_program
    end

    it 'sets the new mint account owner to the Token-2022 program' do
      create_account_ix = composer.instruction_composers.first

      assert_kind_of Solace::Composers::SystemProgramCreateAccountComposer, create_account_ix
      assert_equal program.program_id, create_account_ix.params[:owner]
    end
  end
end

# frozen_string_literal: true

require 'test_helper'

describe Solace::Composers::OpaqueInstructionComposer do
  let(:program_id) { Solace::Keypair.generate.address }
  let(:writable_signer) { Solace::Keypair.generate.address }
  let(:readonly_signer) { Solace::Keypair.generate.address }
  let(:writable_account) { Solace::Keypair.generate.address }
  let(:readonly_account) { Solace::Keypair.generate.address }
  let(:data) { [7, 1, 2, 3] }

  let(:roles) do
    Solace::Utils::AccountContext.new.tap do |roles|
      roles.add_writable_signer(writable_signer)
      roles.add_readonly_signer(readonly_signer)
      roles.add_writable_nonsigner(writable_account)
      roles.add_readonly_nonsigner(readonly_account)
    end
  end

  let(:composer) do
    Solace::Composers::OpaqueInstructionComposer.new(
      program_id: program_id,
      accounts:   [writable_signer, readonly_signer, writable_account, readonly_account],
      data:       data,
      roles:      roles
    )
  end

  it 'declares every account with the role given for it and the program read-only' do
    context = composer.account_context
    flags   = context.pubkey_account_map.keys.to_h { |key| [key, [context.signer?(key), context.writable?(key)]] }

    assert_equal(
      {
        writable_signer => [true, true],
        readonly_signer => [true, false],
        writable_account => [false, true],
        readonly_account => [false, false],
        program_id => [false, false]
      },
      flags
    )
  end

  it 'refuses an account with no role declared' do
    error = assert_raises(ArgumentError) do
      Solace::Composers::OpaqueInstructionComposer.new(
        program_id: program_id,
        accounts:   [writable_signer, Solace::Keypair.generate.address],
        data:       data,
        roles:      roles
      )
    end

    assert_match(/No role declared/, error.message)
  end

  it 're-indexes against the context it is built into, leaving the data untouched' do
    resolving          = Solace::Utils::AccountContext.new
    resolving.accounts = [readonly_account, program_id, writable_account, writable_signer, readonly_signer]

    instruction = composer.build_instruction(resolving)

    assert_equal 1, instruction.program_index
    assert_equal [3, 4, 2, 0], instruction.accounts
    assert_equal data, instruction.data
  end

  it 'answers its program and accounts as strings whatever they were given as' do
    keypair = Solace::Keypair.generate
    roles   = Solace::Utils::AccountContext.new.tap { |context| context.add_writable_signer(keypair) }

    composer = Solace::Composers::OpaqueInstructionComposer.new(
      program_id: Solace::PublicKey.new(Solace::Utils::Codecs.base58_to_bytes(program_id)),
      accounts:   [keypair],
      data:       data,
      roles:      roles
    )

    assert_equal program_id, composer.program_id
    assert_equal [keypair.address], composer.accounts
    assert_equal data, composer.data
  end

  describe 'composing a transfer through it on the validator' do
    before(:all) do
      @connection = Solace::Connection.new(commitment: 'processed')
      bob         = Fixtures.load_keypair('bob')
      @recipient  = Solace::Keypair.generate

      roles = Solace::Utils::AccountContext.new
      roles.add_writable_signer(bob)
      roles.add_writable_nonsigner(@recipient)

      transfer = Solace::Composers::OpaqueInstructionComposer.new(
        program_id: Solace::Constants::SYSTEM_PROGRAM_ID,
        accounts:   [bob, @recipient],
        data:       Solace::Instructions::SystemProgram::TransferInstruction.data(5_000_000),
        roles:      roles
      )

      transaction = Solace::TransactionComposer.new(connection: @connection)
                                               .add_instruction(transfer)
                                               .set_fee_payer(bob)
                                               .compose_transaction
      transaction.sign(bob)

      signature = @connection.send_transaction(transaction.serialize)
      @connection.wait_for_confirmed_signature { signature['result'] }
    end

    it 'lands on chain' do
      assert_equal 5_000_000, @connection.get_balance(@recipient.address)
    end
  end
end

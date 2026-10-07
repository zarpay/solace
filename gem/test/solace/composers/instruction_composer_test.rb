# frozen_string_literal: true

require 'test_helper'

describe Solace::Composers::InstructionComposer do
  let(:program_id) { Solace::Keypair.generate.address }
  let(:writable_signer) { Solace::Keypair.generate.address }
  let(:readonly_signer) { Solace::Keypair.generate.address }
  let(:writable_account) { Solace::Keypair.generate.address }
  let(:readonly_account) { Solace::Keypair.generate.address }
  let(:data) { [7, 1, 2, 3] }

  let(:composer) do
    Solace::Composers::InstructionComposer.new(
      program_id: program_id,
      accounts:   [
        { pubkey: writable_signer, signer: true, writable: true },
        { pubkey: readonly_signer, signer: true, writable: false },
        { pubkey: writable_account, signer: false, writable: true },
        { pubkey: readonly_account, signer: false, writable: false }
      ],
      data:       data
    )
  end

  it 'declares every account with the flags it was given and the program read-only' do
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

  it 're-indexes against the context it is built into, leaving the data untouched' do
    resolving          = Solace::Utils::AccountContext.new
    resolving.accounts = [readonly_account, program_id, writable_account, writable_signer, readonly_signer]

    instruction = composer.build_instruction(resolving)

    assert_equal 1, instruction.program_index
    assert_equal [3, 4, 2, 0], instruction.accounts
    assert_equal data, instruction.data
  end

  it 'exposes what it was given, coerced to strings' do
    keypair  = Solace::Keypair.generate
    composer = Solace::Composers::InstructionComposer.new(
      program_id: Solace::PublicKey.new(Solace::Utils::Codecs.base58_to_bytes(program_id)),
      accounts:   [{ pubkey: keypair, signer: true, writable: true }],
      data:       data
    )

    assert_equal program_id, composer.program_id
    assert_equal [{ pubkey: keypair.address, signer: true, writable: true }], composer.accounts
    assert_equal data, composer.data
  end

  describe 'composing a transfer through it on the validator' do
    before(:all) do
      @connection = Solace::Connection.new(commitment: 'processed')
      bob         = Fixtures.load_keypair('bob')
      @recipient  = Solace::Keypair.generate

      transfer = Solace::Composers::InstructionComposer.new(
        program_id: Solace::Constants::SYSTEM_PROGRAM_ID,
        accounts:   [
          { pubkey: bob, signer: true, writable: true },
          { pubkey: @recipient, signer: false, writable: true }
        ],
        data:       Solace::Instructions::SystemProgram::TransferInstruction.data(5_000_000)
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

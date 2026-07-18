# frozen_string_literal: true

require 'test_helper'

describe Solace::Composers::AddressLookupTableProgramExtendComposer do
  before(:all) do
    connection  = Solace::Connection.new(commitment: 'processed')
    authority   = Fixtures.load_keypair('bob')
    recent_slot = connection.get_slot - 1

    @addresses = [Solace::Keypair.generate.address, Solace::Keypair.generate.address]

    table, bump = Solace::Utils::PDA.find_program_address(
      [authority.address, Solace::Utils::Codecs.encode_le_u64(recent_slot).bytes],
      Solace::Constants::ADDRESS_LOOKUP_TABLE_PROGRAM_ID
    )

    create_composer = Solace::Composers::AddressLookupTableProgramCreateComposer.new(
      table:       table,
      authority:   authority,
      payer:       authority,
      recent_slot: recent_slot,
      bump:        bump
    )

    create_tx = Solace::TransactionComposer
                .new(connection: connection)
                .add_instruction(create_composer)
                .set_fee_payer(authority)
                .compose_transaction

    create_tx.sign(authority)
    create_signature = connection.send_transaction(create_tx.serialize)
    connection.wait_for_confirmed_signature { create_signature['result'] }

    extend_composer = Solace::Composers::AddressLookupTableProgramExtendComposer.new(
      table:     table,
      authority: authority,
      payer:     authority,
      addresses: @addresses
    )

    extend_tx = Solace::TransactionComposer
                .new(connection: connection)
                .add_instruction(extend_composer)
                .set_fee_payer(authority)
                .compose_transaction

    extend_tx.sign(authority)
    extend_signature = connection.send_transaction(extend_tx.serialize)
    connection.wait_for_confirmed_signature { extend_signature['result'] }

    data          = Base64.decode64(connection.get_account_info(table)['data'][0])
    @lookup_table = Solace::Accounts::AddressLookupTable.deserialize(StringIO.new(data))
  end

  it 'appends the addresses to the table in order' do
    assert_equal @addresses, @lookup_table.addresses
  end
end

# frozen_string_literal: true

require 'test_helper'

describe Solace::Composers::AddressLookupTableProgramCreateComposer do
  before(:all) do
    connection  = Solace::Connection.new(commitment: 'processed')
    @authority  = Fixtures.load_keypair('bob')
    recent_slot = connection.get_slot - 1

    @table, bump = Solace::Utils::PDA.find_program_address(
      [@authority.address, Solace::Utils::Codecs.encode_le_u64(recent_slot).bytes],
      Solace::Constants::ADDRESS_LOOKUP_TABLE_PROGRAM_ID
    )

    create_composer = Solace::Composers::AddressLookupTableProgramCreateComposer.new(
      table:       @table,
      authority:   @authority,
      payer:       @authority,
      recent_slot: recent_slot,
      bump:        bump
    )

    tx = Solace::TransactionComposer
         .new(connection: connection)
         .add_instruction(create_composer)
         .set_fee_payer(@authority)
         .compose_transaction

    tx.sign(@authority)

    signature = connection.send_transaction(tx.serialize)
    connection.wait_for_confirmed_signature { signature['result'] }

    data          = Base64.decode64(connection.get_account_info(@table)['data'][0])
    @lookup_table = Solace::Accounts::AddressLookupTable.deserialize(StringIO.new(data))
  end

  it 'creates a lookup table controlled by the authority' do
    assert_equal @authority.address, @lookup_table.authority
  end

  it 'starts with no stored addresses' do
    assert_empty @lookup_table.addresses
  end
end

# frozen_string_literal: true

# Test helper that provisions a real address lookup table on chain (create +
# extend) using the gem's own composers, then waits for it to become usable.
# Returns the table's address. Back-to-back calls land in different slots, so
# each derives a distinct table address.
module LookupTableProvisioner
  extend self

  # Provision a lookup table holding the given addresses
  #
  # @param connection [Solace::Connection] The connection to use
  # @param authority [Solace::Keypair] The table authority and rent payer
  # @param addresses [Array<#to_s>] The addresses to store in the table
  # @return [String] The table's on-chain address
  def provision(connection:, authority:, addresses:)
    recent_slot = connection.get_slot - 1
    table, bump = derive_address(authority, recent_slot)

    transaction = Solace::TransactionComposer
                  .new(connection: connection)
                  .add_instruction(create_composer(table, authority, recent_slot, bump))
                  .add_instruction(extend_composer(table, authority, addresses))
                  .set_fee_payer(authority)
                  .compose_transaction

    transaction.sign(authority)

    signature = connection.send_transaction(transaction.serialize)
    connection.wait_for_confirmed_signature { signature['result'] }

    wait_for_next_slot(connection)

    table
  end

  # Derive the table's program-derived address from [authority, recent_slot]
  def derive_address(authority, recent_slot)
    Solace::Utils::PDA.find_program_address(
      [authority.address, Solace::Utils::Codecs.encode_le_u64(recent_slot).bytes],
      Solace::Constants::ADDRESS_LOOKUP_TABLE_PROGRAM_ID
    )
  end

  def create_composer(table, authority, recent_slot, bump)
    Solace::Composers::AddressLookupTableProgramCreateComposer.new(
      table: table, authority: authority, payer: authority, recent_slot: recent_slot, bump: bump
    )
  end

  def extend_composer(table, authority, addresses)
    Solace::Composers::AddressLookupTableProgramExtendComposer.new(
      table: table, authority: authority, payer: authority, addresses: addresses
    )
  end

  # A table extended in slot N becomes usable in slot N + 1
  def wait_for_next_slot(connection)
    slot = connection.get_slot

    50.times do
      break if connection.get_slot > slot

      sleep 0.2
    end
  end
end

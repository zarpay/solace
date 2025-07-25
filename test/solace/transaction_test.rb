# frozen_string_literal: true

require 'test_helper'

describe Solace::Transaction do
  before do
    # Constants
    @LEGACY_TX = 'AQTOlTZsUqzg6u0IVycmib4bKX7B2T3NcojpY41cl/eEiAASMp3Jw2BRxHjljjzkYIaJ9riCZGaJPs8d1epyqgwBAAQH66k2oxCf1NeH/qx+lTO8hVJaIRFdbOZ9gcllmRxaOY4ePuaeKDiITwFZ8rCSkE+db/L5QJy0xGAauYopfRdP4V8H9slNVtuqE+OCdY1zzix2FyAYSUozZZvscFh9+YmDAwZGb+UhFzL/7K26csOb57yM5bvF9xJrLEObOkAAAAAG3fbh12Whk9nL4UbO63msHLSF7V9bN5E6jPWFfv8AqSKtWWLMxAr/lb3bGSFoFz4J32rEnvAT3IaBkhYHxQ+aO0Qss5EhV/E6kz0BNCgtAytf/s0Botvxt3kGCN8ALqd+cK7yZ+2vzULI/dD7q+Kko7KdVLNIL3Fdfxhts2TjigMDAAUCNCEAAAMACQMgoQcAAAAAAAQGAgYBAAAFCgwQJwAAAAAAAAY='
    @VERSIONED_TX = 'Aaq/sJpfXp/rur6pUDoniGGiqJr9VnsjNjPgB/nF7yct/yvZDkZK83NVm35gngpQXVG8PScoCPZgd0rGrK1b9QSAAQADC5kYZngZ374Y0pb6toNS8GHchmk84eLPpT4FJYf5crqoHSD5PZKUQwLgiCHryaf8nYk/9Al8YGxaabuPi6YsD7E417niAzAcHpomUF/GETKHRYOgv/P1/BLiytOES8dmZqGhggNSUXM2XTqsvfg3BSoR82hoDtF5DPfMmxCnw9kDJjx8nnqzm2jnudUkmtT7OefnKxmLLPwmxna0+Ur5JyNmFYSl4ZtUmvGPp0x4olkD8HeiBYjO1miLKcSNaSmFs2m8wpNK/w2erNxNBqLyr4Ug7KVaSU0C5Mfzx9IdUpl+Z/n96hEZ1/m4PAL+pZejjM0ChyLCm8l9UMVuyGThaW8DBkZv5SEXMv/srbpyw5vnvIzlu8X3EmssQ5s6QAAAAEPgBQCBHk9mdcAVjyWfKoLRkuYzPGFr1h8etE0/GSomBHnVLe2/a8Xs0J2EU0o0rqWXUEOzb9ArJGULtYRDWVx9jg0F4KP4uEEqvdsAUZCEMfqzYLqwiV0Msd0Ri7lW6gQIAAkDAQAAAAAAAAAIAAUCs3QJAAobGwAWHRsAARYEBQYHAwMJHRsADxYRBRACAgIcJuUXy5d6460qAAIAAAACEQECEQCZzggAAAAAAJnOCAAAAAAAAAAAChkbABYfGx4gABYUFRcTEhobGBkAFw4LFgwNJOUXy5d6460qAAIAAAACAwIDcP0/AAAAAABw/T8AAAAAAAAAAARAZBKwJRxRnGTsI+T6zu8hUOLI6lctSWvf4+Ycva/8GQTf4ePkBODi5QKEgS7T31AwSpZVXVVwlUfGebniA/eoCIKFzzwMS83eFAN+WlsCfVmHN+v4qZMpECh9knvF52aQMItF99mqKn4VgxJJ0eR3EQT7+Pr8A/79+SlzukoCCkEx+Sj3pIVWahbnIjqag3d4ZCeUmaJnBlAsAqANAA=='

    # IOs
    legacy_io = Solace::Utils::Codecs.base64_to_bytestream(@LEGACY_TX)
    versioned_io = Solace::Utils::Codecs.base64_to_bytestream(@VERSIONED_TX)

    # Transactions
    @legacy_tx = Solace::Transaction.deserialize(legacy_io)
    @versioned_tx = Solace::Transaction.deserialize(versioned_io)
  end

  describe '#serialize' do
    it 'returns serialized legacy transaction' do
      assert_equal @LEGACY_TX, @legacy_tx.serialize
    end

    it 'returns serialized versioned transaction' do
      assert_equal @VERSIONED_TX, @versioned_tx.serialize
    end
  end

  describe 'Multiple Signatures' do
    # Make sure keypairs are loaded
    let(:bob) { Fixtures.load_keypair('bob') }
    let(:alice) { Fixtures.load_keypair('anna') }
    let(:payer) { Fixtures.load_keypair('payer') }

    let(:nobody) { Solace::Keypair.generate }
    let(:unknown_signer) { Solace::Keypair.generate }

    # Make sure connection is loaded
    let(:conn) { Solace::Connection.new }

    before do
      # Arrange
      @msg = Solace::Message.new

      # 1 signer will serve as payer
      # 1 signer will be account 1
      # 1 signer will be account 2
      @msg.header = [
        3,
        0,
        1
      ]

      # Add accounts
      @msg.accounts = [
        payer.address,
        bob.address,
        alice.address,
        nobody.address,
        Solace::Constants::SYSTEM_PROGRAM_ID
      ]

      # Get latest blockhash
      @msg.recent_blockhash = conn.get_latest_blockhash

      @msg.instructions = [
        # Send money from account 1 to account 2
        Solace::Instructions::SystemProgram::TransferInstruction.build(
          to_index: 2,
          from_index: 1,
          program_index: 4,
          lamports: 10_000_000 # 0.01 SOL
        ),
        # Send money from account 2 to account 3
        Solace::Instructions::SystemProgram::TransferInstruction.build(
          to_index: 3,
          from_index: 2,
          program_index: 4,
          lamports: 10_000_000 # 0.01 SOL
        )
      ]

      @tx = Solace::Transaction.new(message: @msg)
    end

    it 'should add multiple signatures to the transaction' do
      @tx.sign(payer, bob, alice)

      assert_equal 3, @tx.signatures.size
    end

    it 'should reject unpresent signers' do
      error = assert_raises(ArgumentError) { @tx.sign(unknown_signer) }
      assert_equal 'Public key not found in transaction', error.message
    end

    it 'should order the signatures according to the accounts' do
      # NOTE: The ording of this test is important, as it simulates a
      # transaction where the order by which signatures get added being
      # random, while the transaction still being valid.

      alice_signature = @tx.sign(alice).first
      # Alice is account 2 at index 2 of the accounts array
      assert_equal alice_signature, @tx.signatures[2]

      payer_signature = @tx.sign(payer).first
      # Payer is account 0 at index 0 of the accounts array
      assert_equal payer_signature, @tx.signatures[0]

      bob_signature = @tx.sign(bob).first
      # Bob is account 1 at index 1 of the accounts array
      assert_equal bob_signature, @tx.signatures[1]
    end

    it 'should handle placeholder signatures' do
      @tx.signatures = 3.times.map { Solace::Utils::Codecs.base58_to_binary('1' * 64) }

      bob_signature = @tx.sign(bob).first
      # Bob is account 1 at index 1 of the accounts array
      assert_equal bob_signature, @tx.signatures[1]

      # First handoff: Simulate a transaction being sent to another server or node
      one_of_three_signed_tx = Solace::Transaction.from(@tx.serialize)

      alice_signature = one_of_three_signed_tx.sign(alice).first
      # Alice is account 2 at index 2 of the accounts array
      assert_equal alice_signature, one_of_three_signed_tx.signatures[2]

      # Second handoff: Simulate a transaction being sent to another server or node
      two_of_three_signed_tx = Solace::Transaction.from(one_of_three_signed_tx.serialize)

      payer_signature = two_of_three_signed_tx.sign(payer).first
      # Payer is account 0 at index 0 of the accounts array
      assert_equal payer_signature, two_of_three_signed_tx.signatures[0]

      # Third handoff: Simulate a transaction being sent to another server or node
      three_of_three_signed_tx = Solace::Transaction.from(two_of_three_signed_tx.serialize)

      # All signatures should be present
      assert_equal 3, three_of_three_signed_tx.signatures.size
    end

    it 'should successfully send a transaction' do
      # Sign the transaction
      @tx.sign(bob)
      @tx.sign(alice)

      # In a Solana transaction, the first signature (payer) in the signatures array gets
      # used as the signature of the transaction. If the returned result is equal to the
      # signature of the payer, the transaction was successfully sent.
      raw_payer_signature = @tx.sign(payer).first

      # Convert the signature to base58
      encoded_payer_signature = Solace::Utils::Codecs.binary_to_base58(raw_payer_signature)

      # Send the transaction
      conn.wait_for_confirmed_signature do
        response = conn.send_transaction(@tx.serialize)

        assert_equal encoded_payer_signature, response['result']

        # Return the result signature to the block
        response['result']
      end
    end
  end
end

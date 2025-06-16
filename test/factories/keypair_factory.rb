# frozen_string_literal: true

FactoryBot.define do
  factory :funded_keypair, class: Solace::Keypair do
    transient do
      amount { 10_000_000_000 }
    end

    initialize_with do
      keypair = Solace::Keypair.generate

      conn = Solace::Connection.new
      
      # Request airdrop and wait for confirmation
      conn.wait_for_confirmed_signature do
        conn.request_airdrop(keypair.address, amount)['result']
      end

      # Return the keypair
      keypair
    end
  end
end

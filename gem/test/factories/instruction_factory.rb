# frozen_string_literal: true

# require 'factory_bot'

FactoryBot.define do
  factory :instruction, class: 'Solace::Instruction' do
    # Instruction type
    program_index { nil }
    accounts { [] }
    data { [] }

    trait :as_transfer do
      program_index { 2 }
      accounts { [0, 1] }
      data { [2, 0, 0, 0] + [100_000_000].pack('Q<').bytes }
    end

    trait :as_transfer_checked do
      program_index { 2 }
      accounts { [0, 1] }
      data { [12] + [100_000_000].pack('Q<').bytes + [6] }
    end

    trait :as_create_account do
      program_index { 2 }
      accounts { [0, 1] }
      data do
        [0, 0, 0,
         0] + [1_000_000_000].pack('Q<').bytes + [100].pack('Q<').bytes + [Solace::Constants::SYSTEM_PROGRAM_ID].pack('H*')
      end
    end
  end
end

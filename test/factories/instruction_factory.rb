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
  end
end
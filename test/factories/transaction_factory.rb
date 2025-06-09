# frozen_string_literal: true

require 'factory_bot'

FactoryBot.define do
  factory :transaction, class: 'Solace::Transaction' do
    signatures { [] }
    message { nil }
    
    trait :with_legacy_transfer do
      message { build(:legacy_message, :with_transfer_instruction) }
    end

    trait :with_versioned_transfer do
      message { build(:versioned_message, :with_transfer_instruction) }
    end
  end
end

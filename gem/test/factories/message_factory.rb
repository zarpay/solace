# frozen_string_literal: true

require 'factory_bot'

FactoryBot.define do
  factory :message, class: 'Solace::Message' do
    version { nil }
    header { [0, 0, 0] }
    accounts { [] }
    recent_blockhash { nil }
    instructions { [] }
    address_lookup_tables { [] }
  end

  factory :versioned_message, parent: :message do
    version { 0 }
  end

  factory :legacy_message, parent: :message do
    version { nil }
  end

  trait :with_transfer_instruction do
    # Header
    header do
      [
        1, # num_required_signatures
        0, # num_readonly_signed
        1  # num_readonly_unsigned
      ]
    end

    # Accounts
    accounts do
      [
        '2VFAhjXBhMuEbmcTtjYXAZX4oVPhr3im7yb8RmaBofU6',
        'cbk37cQDdSqarxFTD9oG9c31YhcGZzd2QJwuGmWZhLL',
        Solace::Constants::SYSTEM_PROGRAM_ID
      ]
    end

    # Recent blockhash
    recent_blockhash { '9s5BVd3xd3MinQcJbCCTBwXn6WRukcdEwgC2ZjktjKqu' }

    # Transfer instruction
    instructions do
      [
        Solace::Instructions::SystemProgram::TransferInstruction.build(
          to_index: 1,
          from_index: 0,
          program_index: 2,
          lamports: 10_000_000 # 0.01 SOL
        )
      ]
    end
  end
end

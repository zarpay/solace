require 'test_helper'

class TransactionTest < Minitest::Test
  # Example legacy transaction (base64 string)
  LEGACY_TX = 'ATb9iy8YGDhu3n/lblX6vutFwL08V2vO6SWM0tzvXyYKfkl+JHJ+Ne3LQL2ST3bFz+yq8WKY6xRl1gT6Hl7OfwABAAEDFhf39JpMHlteXqQdhkKyBMHDjE/FI1nKB1VAYwoX8usJHpx5omCOgQLd62o8TZKcoP4rwMXr3VxZW7WY5RVdEQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAApnfy5i7sTd9C9sheZ1m39A4THe+MBUS0Mg0CR0ElXsIBAgIAAQwCAAAAQEIPAAAAAAA='

  # Example versioned transaction (base64 string)
  VERSIONED_TX = 'AWOGHsLk8vtOCVpO3U4nN0VhkzL5SaV+W9ChrclD0WuGFxYnT2RFc4nfmWNukLMmxNZGmE48b2rTpTlQ48VUvA+AAQABAxYX9/SaTB5bXl6kHYZCsgTBw4xPxSNZygdVQGMKF/LrCR6ceaJgjoEC3etqPE2SnKD+K8DF691cWVu1mOUVXREAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAALpuKeTKLDGR061cQispY/jwMv+wzUE4W1l7VC7UbqRjAQICAAEMAgAAAEBCDwAAAAAAAA=='

  def test_unpack_legacy
    stream = Solana::Utils::Codecs.base64_to_bytestream(LEGACY_TX)
    tx = Solana::Transaction.unpack(stream)
    assert_equal 1, tx.signatures.size
    assert_equal 3, tx.account_keys.size
    assert_equal 1, tx.instructions.size
    assert_nil tx.version
    assert_kind_of Array, tx.message_header
    assert_kind_of String, tx.recent_blockhash
  end

  def test_unpack_versioned
    stream = Solana::Utils::Codecs.base64_to_bytestream(VERSIONED_TX)
    tx = Solana::Transaction.unpack(stream)
    assert_equal 1, tx.signatures.size
    assert_equal 3, tx.account_keys.size
    assert_equal 1, tx.instructions.size
    assert_equal 0, tx.version
    assert_kind_of Array, tx.message_header
    assert_kind_of String, tx.recent_blockhash
  end
end
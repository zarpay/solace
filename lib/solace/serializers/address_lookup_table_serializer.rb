# frozen_string_literal: true

# =============================
# Address Lookup Table Serializer
# =============================
#
# Serializes a Solana address lookup table to a binary format.
class Solace::Serializers::AddressLookupTableSerializer < Solace::Serializers::BaseSerializer
  # @!attribute steps
  #   An ordered list of methods to serialize the address lookup table
  # 
  # @return [Array] The steps to serialize the address lookup table
  self.steps = [
    :encode_account,
    :encode_writable_indexes,
    :encode_readonly_indexes
  ]

  # Encodes the account of the address lookup table
  # 
  # The BufferLayout is:
  #   - [Account key (32 bytes)]
  # 
  # @return [Array<Integer>] The bytes of the encoded account
  def encode_account
    Codecs.base58_to_bytes(record.account)
  end

  # Encodes the writable indexes of the address lookup table
  # 
  # The BufferLayout is:
  #   - [Number of writable indexes (compact u16)]
  #   - [Writable indexes (variable length u8)]
  # 
  # @return [Array<Integer>] The bytes of the encoded writable indexes
  def encode_writable_indexes
    Codecs.encode_compact_u16(record.writable_indexes.size).bytes + record.writable_indexes
  end

  # Encodes the readonly indexes of the address lookup table
  # 
  # The BufferLayout is:
  #   - [Number of readonly indexes (compact u16)]
  #   - [Readonly indexes (variable length u8)]
  # 
  # @return [Array<Integer>] The bytes of the encoded readonly indexes
  def encode_readonly_indexes
    Codecs.encode_compact_u16(record.readonly_indexes.size).bytes + record.readonly_indexes
  end
end
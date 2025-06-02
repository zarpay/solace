# encoding: ASCII-8BIT

# =============================
# Address Lookup Table
# =============================
# 
# Class representing an address lookup table.
# 
# The BufferLayout is:
#   - [Account key (32 bytes)]
#   - [Number of writable indexes (compact u16)]
#   - [Writable indexes (variable length)]
#   - [Number of readonly indexes (compact u16)]
#   - [Readonly indexes (variable length)]
# 
class Solana::AddressLookupTable
  include Solana::Concerns::BinarySerializable

  # The account keys in the address lookup table
  attr_accessor :account
  
  # The writable indexes in the address lookup table
  attr_accessor :writable_indexes
  
  # The readonly indexes in the address lookup table
  attr_accessor :readonly_indexes

  class << self
    # Parse address lookup table from io stream
    # 
    # @param io [IO or StringIO] The input to read bytes from.
    # @return [Solana::AddressLookupTable] Parsed address lookup table object
    def deserialize(io)
      Solana::Serializers::AddressLookupTableDeserializer.call(io)
    end
  end

  # Serialize the address lookup table
  # 
  # @return [String] The serialized address lookup table (base64)
  def serialize
    Solana::Serializers::AddressLookupTableSerializer.call(self)
  end
end

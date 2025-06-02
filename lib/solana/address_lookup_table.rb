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
  include Solana::Utils

  # The account keys in the address lookup table
  attr_reader :account_key
  
  # The writable indexes in the address lookup table
  attr_reader :writable_indexes
  
  # The readonly indexes in the address lookup table
  attr_reader :readonly_indexes

  # Parse address lookup table from io stream
  # 
  # @param io [IO or StringIO] The input to read bytes from.
  # @return [Solana::AddressLookupTable] Parsed address lookup table object
  def self.unpack(io)
    alt = new

    alt._next_extract_account_key(io)
    alt._next_extract_writable_indexes(io)
    alt._next_extract_readonly_indexes(io)

    alt
  end

  # Extract the account key from the transaction
  # 
  # @param io [IO or StringIO] The input to read bytes from.
  # @return [String] The account key
  def _next_extract_account_key(io)
    @account_key = Codecs.bytes_to_base58 io.read(32).bytes
  end

  # Extract the writable indexes from the transaction
  # 
  # @param io [IO or StringIO] The input to read bytes from.
  # @return [Array] The writable indexes
  def _next_extract_writable_indexes(io)
    writable_length, _ = Codecs.decode_compact_u16(io)
    @writable_indexes = io.read(writable_length).unpack("C*")
  end

  # Extract the readonly indexes from the transaction
  # 
  # @param io [IO or StringIO] The input to read bytes from.
  # @return [Array] The readonly indexes
  def _next_extract_readonly_indexes(io)
    readonly_length, _ = Codecs.decode_compact_u16(io)
    @readonly_indexes = io.read(readonly_length).unpack("C*")
  end
end

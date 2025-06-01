# encoding: ASCII-8BIT

class Solana::Transaction
  include Solana::Utils

  # Signatures of the transaction (base58 encoded)
  attr_accessor :signatures

  # Version number of the transaction
  attr_accessor :version
  
  # Message header of the transaction
  attr_accessor :message_header

  # Account keys of the transaction
  attr_accessor :account_keys

  # Recent blockhash of the transaction
  attr_accessor :recent_blockhash

  # Instructions of the transaction
  attr_accessor :instructions

  # Address table lookup of the transaction
  attr_accessor :address_lookup_table

  class << self
    # Parse transaction from base64 string
    # 
    # Args:
    #   io (IO or StringIO): The input to read bytes from.
    # 
    # Returns:
    #   Transaction: Parsed transaction object
    # 
    def unpack(io)
      # Create new transaction object
      tx = new

      tx._next_extract_signatures(io)
      tx._next_extract_version(io)
      tx._next_extract_message_header(io)
      tx._next_extract_account_keys(io)
      tx._next_extract_recent_blockhash(io)
      tx._next_extract_instructions(io)
      tx._next_extract_address_lookup_table(io) unless tx.version.nil?
      
      raise "End of message not reached. Transaction data is too long." unless io.eof?

      tx
    end
  end

  # Check if the transaction is a legacy transaction or versioned transaction
  # 
  # Returns:
  #   Boolean: True if the transaction is a legacy transaction, false otherwise
  # 
  def versioned?
    version.nil?
  end

  # Extract signatures from the transaction
  # 
  # Args:
  #   io (IO or StringIO): The input to read bytes from.
  # 
  # Returns:
  #   Signatures: Array of base58 encoded signatures
  # 
  def _next_extract_signatures(io)
    count, _ = Codecs.decode_compact_u16(io)
    @signatures = count.times.map do
      Codecs.bytes_to_base58 io.read(64).bytes 
    end
  end

  # Extract version from the transaction
  # 
  # Checks for version prefix and extracts version. If the prefix is not found, it
  # assumes a legacy transaction and sets no version.
  # 
  # Args:
  #   io (IO or StringIO): The input to read bytes from.
  # 
  # Returns:
  #   Version: The version of the transaction
  # 
  def _next_extract_version(io)
    next_byte = io.read(1).unpack1("C")

    # Check version prefix
    if next_byte & 0x80 == 0x80
      @version = next_byte & 0x7F
    else 
      # Rewind one byte to restore position
      io.seek(-1, IO::SEEK_CUR)
      @version = nil
    end
  end

  # Extract message header from the transaction
  # 
  # Args:
  #   io (IO or StringIO): The input to read bytes from.
  # 
  # Returns:
  #   MessageHeader: The message header of the transaction
  # 
  def _next_extract_message_header(io)
    @message_header = io.read(3).bytes
  end

  # Extract account keys from the transaction
  # 
  # Args:
  #   io (IO or StringIO): The input to read bytes from.
  # 
  # Returns:
  #   AccountKeys: The account keys of the transaction
  # 
  def _next_extract_account_keys(io)
    count, _ = Codecs.decode_compact_u16(io)
    @account_keys = count.times.map do
      Codecs.bytes_to_base58 io.read(32).bytes 
    end        
  end

  # Extract recent blockhash from the transaction
  # 
  # Args:
  #   io (IO or StringIO): The input to read bytes from.
  # 
  # Returns:
  #   String: The recent blockhash of the transaction
  # 
  def _next_extract_recent_blockhash(io)
    @recent_blockhash = Codecs.bytes_to_base58 io.read(32).bytes
  end

  # Extract instructions from the transaction
  # 
  # Args:
  #   io (IO or StringIO): The input to read bytes from.
  # 
  # Returns:
  #   Instructions: The instructions of the transaction
  # 
  def _next_extract_instructions(io)
    count, _ = Codecs.decode_compact_u16(io)
    @instructions = count.times.map do 
      Solana::Instruction.unpack(io)
    end
  end

  # Extract address lookup table from the transaction
  # 
  # Args:
  #   io (IO or StringIO): The input to read bytes from.
  # 
  # Returns:
  #   AddressLookupTable: The address lookup table of the transaction
  # 
  def _next_extract_address_lookup_table(io)
    count, _ = Codecs.decode_compact_u16(io)
    @address_lookup_table = count.times.map do
      Solana::AddressLookupTable.unpack(io)
    end
  end
end

class Solana::Instruction
  include Solana::Utils
  
  # The program index
  attr_accessor :program_index
  
  # The accounts
  attr_accessor :accounts
  
  # The instruction data
  attr_accessor :data
  
  # Parse instruction from io stream
  # 
  # The BufferLayout is:
  #   - [Program index (1 byte)]
  #   - [Number of accounts (compact u16)]
  #   - [Accounts (variable length)]
  #   - [Data length (compact u16)]
  #   - [Data (variable length)]
  # 
  # Args:
  #   io (IO or StringIO): The input to read bytes from.
  # 
  # Returns:
  #   Instruction: Parsed instruction object
  # 
  def self.unpack(io)
    ix = new

    ix._next_extract_program_index(io)
    ix._next_extract_num_accounts_in_instruction(io)
    ix._next_extract_data(io)

    ix
  end

  # Extracts the program index from the instruction
  # 
  # Args:
  #   io (IO or StringIO): The input to read bytes from.
  # 
  # Returns:
  #   Integer: The program index
  # 
  def _next_extract_program_index(io)
    @program_index = io.read(1).ord
  end

  # Extracts the accounts from the instruction
  # 
  # Args:
  #   io (IO or StringIO): The input to read bytes from.
  # 
  # Returns:
  #   Array: The accounts
  # 
  def _next_extract_num_accounts_in_instruction(io)
    count, _ = Codecs.decode_compact_u16(io)
    @accounts = count.times.map { io.read(1).ord }
  end

  # Extracts the instruction data from the instruction
  # 
  # Args:
  #   io (IO or StringIO): The input to read bytes from.
  # 
  # Returns:
  #   Array: The instruction data
  # 
  def _next_extract_data(io)
    length, _ = Codecs.decode_compact_u16(io)
    @data = io.read(length).unpack("C*")
  end
end
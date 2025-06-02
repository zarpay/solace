# frozen_string_literal: true

# =============================
# Instruction
# =============================
#
# Class representing a Solana instruction.
#
# The BufferLayout is:
#   - [Program index (1 byte)]
#   - [Number of accounts (compact u16)]
#   - [Accounts (variable length)]
#   - [Data length (compact u16)]
#   - [Data (variable length)]
#
class Solana::Instruction
  include Solana::Concerns::BinarySerializable
  
  # The program index
  attr_accessor :program_index
  
  # The accounts
  attr_accessor :accounts
  
  # The instruction data
  attr_accessor :data
  
  class << self
    # Parse instruction from io stream
    # 
    # @param io [IO or StringIO] The input to read bytes from.
    # @return [Solana::Instruction] Parsed instruction object
    def deserialize(io)
      Solana::Serializers::InstructionDeserializer.call(io)
    end
  end

  # Serializes the instruction to a binary format
  # 
  # @return [String] The serialized instruction (binary)
  def serialize
    Solana::Serializers::InstructionSerializer.call(self)
  end
end
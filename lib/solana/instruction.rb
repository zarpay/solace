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
class Solana::Instruction < Solana::SerializableRecord
  # @!const SERIALIZER
  #   @return [Solana::Serializers::InstructionSerializer] The serializer for the instruction
  SERIALIZER = Solana::Serializers::InstructionSerializer

  # @!const DESERIALIZER
  #   @return [Solana::Serializers::InstructionDeserializer] The deserializer for the instruction
  DESERIALIZER = Solana::Serializers::InstructionDeserializer
  
  # @!attribute [rw] program_index
  #   @return [Integer] The program index of the instruction
  attr_accessor :program_index
  
  # @!attribute [rw] accounts
  #   @return [Array<Integer>] The accounts of the instruction
  attr_accessor :accounts
  
  # @!attribute [rw] data
  #   @return [Array<Integer>] The instruction data
  attr_accessor :data
end
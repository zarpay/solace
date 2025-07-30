# frozen_string_literal: true

module Solace
  # !@class Instruction
  #
  # A class representing a Solana instruction. Handles serialization and deserialization of instruction fields.
  #
  # The BufferLayout is:
  #   - [Program index (1 byte)]
  #   - [Number of accounts (compact u16)]
  #   - [Accounts (variable length)]
  #   - [Data length (compact u16)]
  #   - [Data (variable length)]
  #
  # @return [Class]
  class Instruction < Solace::SerializableRecord
    # @!const SERIALIZER
    #   @return [Solace::Serializers::InstructionSerializer] The serializer for the instruction
    SERIALIZER = Solace::Serializers::InstructionSerializer

    # @!const DESERIALIZER
    #   @return [Solace::Serializers::InstructionDeserializer] The deserializer for the instruction
    DESERIALIZER = Solace::Serializers::InstructionDeserializer

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
end

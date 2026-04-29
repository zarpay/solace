# frozen_string_literal: true

module Solace
  # Class representing a Solana instruction.
  #
  # Handles serialization and deserialization of instruction fields. Instructions are used to
  # encode the data that is sent to a program on the Solana blockchain. Instructions are part of
  # transaction messages. All instruction builders and instruction composers return an instance of
  # this class.
  #
  # The BufferLayout is:
  #   - [Program index (1 byte)]
  #   - [Number of accounts (compact u16)]
  #   - [Accounts (variable length)]
  #   - [Data length (compact u16)]
  #   - [Data (variable length)]
  #
  # @example
  #   instruction = Solace::Instruction.new(
  #     program_index: 0,
  #     accounts: [1, 2, 3],
  #     data: [4, 5, 6]
  #   )
  #
  # @since 0.0.1
  class Instruction
    include Solace::Concerns::BinarySerializable

    # @!attribute SERIALIZER
    #   @return [Solace::Serializers::InstructionSerializer] The serializer for the instruction
    SERIALIZER = Solace::Serializers::InstructionSerializer

    # @!attribute DESERIALIZER
    #   @return [Solace::Serializers::InstructionDeserializer] The deserializer for the instruction
    DESERIALIZER = Solace::Serializers::InstructionDeserializer

    # @!attribute  [rw] program_index
    #   @return [Integer] The program index of the instruction
    attr_accessor :program_index

    # @!attribute  [rw] accounts
    #   @return [Array<Integer>] The accounts of the instruction
    attr_accessor :accounts

    # @!attribute  [rw] data
    #   @return [Array<Integer>] The instruction data
    attr_accessor :data
  end
end

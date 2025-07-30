# frozen_string_literal: true

module Solace
  # Solace::Message represents the message portion of a Solana transaction (legacy or versioned). It handles
  # serialization and deserialization of message fields.
  #
  # @example
  #   message = Solace::Message.new(
  #     version: 0,
  #     header: [0, 0, 0],
  #     accounts: ['11111111111111111111111111111111'],
  #     recent_blockhash: '11111111111111111111111111111111',
  #     instructions: [],
  #     address_lookup_tables: []
  #   )
  #
  # @since 0.0.1
  class Message
    include Solace::Concerns::BinarySerializable

    # @!attribute SERIALIZER
    #   @return [Solace::Serializers::MessageSerializer] The serializer for the message
    SERIALIZER = Solace::Serializers::MessageSerializer

    # @!attribute DESERIALIZER
    #   @return [Solace::Serializers::MessageDeserializer] The deserializer for the message
    DESERIALIZER = Solace::Serializers::MessageDeserializer

    # @!attribute [rw] version
    #   @return [Integer, nil] Message version (nil for legacy)
    attr_accessor :version

    # @!attribute [rw] header
    #   @return [Array<Integer>] Message header [num_required_signatures, num_readonly_signed, num_readonly_unsigned]
    attr_accessor :header

    # @!attribute [rw] accounts
    #   @return [Array<String>] Account public keys (base58)
    attr_accessor :accounts

    # @!attribute [rw] recent_blockhash
    #   @return [String] Recent blockhash (base58)
    attr_accessor :recent_blockhash

    # @!attribute [rw] instructions
    #   @return [Array<Solace::Instruction>] Instructions in the message
    attr_accessor :instructions

    # @!attribute [rw] address_lookup_tables
    #   @return [Array<Solace::AddressLookupTable>] Address lookup tables (for versioned messages)
    attr_accessor :address_lookup_tables

    # Initialize a new Message
    #
    # @param version [Integer, nil] Message version (nil for legacy)
    # @param accounts [Array<String>] Account public keys (base58)
    # @param instructions [Array<Solace::Instruction>] Instructions in the message
    # @param recent_blockhash [String] Recent blockhash (base58)
    # @param header [Array<Integer>] Message header
    # @param address_lookup_tables [Array<Solace::AddressLookupTable>]
    def initialize(
      version: nil,
      accounts: [],
      instructions: [],
      recent_blockhash: nil,
      header: [0, 0, 0],
      address_lookup_tables: []
    )
      super()

      @version = version
      @header = header
      @accounts = accounts
      @recent_blockhash = recent_blockhash
      @instructions = instructions
      @address_lookup_tables = address_lookup_tables
    end

    # Check if the message is versioned
    #
    # @return [Boolean] True if the message is versioned, false otherwise
    def versioned?
      !version.nil?
    end

    # Returns the number of required signatures
    #
    # @return [Integer] The number of required signatures
    def num_required_signatures
      header[0]
    end

    # Returns the number of readonly signed accounts
    #
    # @return [Integer] The number of readonly signed accounts
    def num_readonly_signed_accounts
      header[1]
    end

    # Returns the number of readonly unsigned accounts
    #
    # @return [Integer] The number of readonly unsigned accounts
    def num_readonly_unsigned_accounts
      header[2]
    end
  end
end

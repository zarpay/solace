# frozen_string_literal: true

module Solana
  # =============================
  # Message
  # =============================
  #
  # Represents the message portion of a Solana transaction (legacy or versioned).
  # Handles serialization and deserialization of message fields.
  #
  # @see https://docs.solana.com/developing/programming-model/transactions#messages
  class Message
    include Solana::Concerns::BinarySerializable

    # @return [Integer, nil] Message version (nil for legacy)
    attr_accessor :version
    # @return [Array<Integer>] Message header [num_required_signatures, num_readonly_signed, num_readonly_unsigned]
    attr_accessor :header
    # @return [Array<String>] Account public keys (base58)
    attr_accessor :accounts
    # @return [String] Recent blockhash (base58)
    attr_accessor :recent_blockhash
    # @return [Array<Solana::Instruction>] Instructions in the message
    attr_accessor :instructions
    # @return [Array<Solana::AddressLookupTable>] Address lookup tables (for versioned messages)
    attr_accessor :address_lookup_tables

    class << self
    # Deserialize a message from binary
      # @param io [IO] binary message
      # @return [Solana::Message]
      def self.deserialize(io)
        Solana::Serializers::MessageDeserializer.call(io)
      end
    end

    # Initialize a new Message
    #
    # @param version [Integer, nil] Message version (nil for legacy)
    # @param accounts [Array<String>] Account public keys (base58)
    # @param instructions [Array<Solana::Instruction>] Instructions in the message
    # @param recent_blockhash [String] Recent blockhash (base58)
    # @param header [Array<Integer>] Message header [num_required_signatures, num_readonly_signed, num_readonly_unsigned]
    # @param address_lookup_tables [Array<Solana::AddressLookupTable>]
    def initialize(
      version: nil, 
      accounts: [], 
      instructions: [], 
      recent_blockhash: nil, 
      header: [0, 0, 0], 
      address_lookup_tables: []
    )
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

    # Serialize the message to binary
    # @return [String] serialized message (binary)
    def serialize
      Solana::Serializers::MessageSerializer.call(self)
    end
  end
end

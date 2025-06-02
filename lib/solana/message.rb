# frozen_string_literal: true

# =============================
# Message
# =============================
#
# Represents the message portion of a Solana transaction (legacy or versioned).
# Handles serialization and deserialization of message fields.
class Solana::Message < Solana::SerializableRecord
  # @!const SERIALIZER
  #   @return [Solana::Serializers::MessageSerializer] The serializer for the message
  SERIALIZER = Solana::Serializers::MessageSerializer

  # @!const DESERIALIZER
  #   @return [Solana::Serializers::MessageDeserializer] The deserializer for the message
  DESERIALIZER = Solana::Serializers::MessageDeserializer

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
  #   @return [Array<Solana::Instruction>] Instructions in the message
  attr_accessor :instructions

  # @!attribute [rw] address_lookup_tables
  #   @return [Array<Solana::AddressLookupTable>] Address lookup tables (for versioned messages)
  attr_accessor :address_lookup_tables

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
end

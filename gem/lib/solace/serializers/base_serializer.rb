# frozen_string_literal: true

module Solace
  # The Serializers module contains classes for converting data structures to and
  # from the binary format required by the Solana runtime.
  #
  # Solana transactions, messages, and instructions use a compact binary encoding
  # for efficiency. The serializers in this module handle the conversion between
  # Ruby objects and this binary format, including proper handling of:
  # - Compact array encoding
  # - Account key serialization
  # - Instruction data packing
  # - Message header construction
  #
  # Each serializer corresponds to a specific data structure:
  # - {Solace::Serializers::TransactionSerializer} - Complete transactions
  # - {Solace::Serializers::MessageSerializer} - Transaction messages
  # - {Solace::Serializers::InstructionSerializer} - Individual instructions
  # - {Solace::Serializers::AddressLookupTableSerializer} - Address lookup tables
  #
  # Each deserializer handles the inverse operation, converting binary data:
  # - {Solace::Serializers::TransactionDeserializer}
  # - {Solace::Serializers::MessageDeserializer}
  # - {Solace::Serializers::InstructionDeserializer}
  # - {Solace::Serializers::AddressLookupTableDeserializer}
  #
  # These utilities are primarily used internally by other parts of the gem, but
  # can also be used directly for advanced use cases.
  #
  # @see Solace::Serializers::BaseSerializer
  # @see Solace::Serializers::BaseDeserializer
  # @since 0.0.1
  module Serializers
    # Autoload serializers
    autoload :TransactionSerializer, 'solace/serializers/transaction_serializer'
    autoload :MessageSerializer, 'solace/serializers/message_serializer'
    autoload :InstructionSerializer, 'solace/serializers/instruction_serializer'
    autoload :AddressLookupTableSerializer, 'solace/serializers/address_lookup_table_serializer'

    # The base serializer class
    #
    # This class provides a consistent interface for serializing records.
    #
    # @abstract
    # @since 0.0.1
    class BaseSerializer
      include Solace::Utils

      # @!attribute record
      #   The record instance being serialized.
      #
      # @return [Record] The serialized record.
      attr_reader :record

      # Initialize a new serializer
      #
      # @param record [Record] The record to serialize
      # @return [BaseSerializer] The new serializer object
      def initialize(record)
        super()
        @record = record
      end

      # Serializes the record
      #
      # @return [String] The serialized record (base64)
      def call
        bin = self.class
                  .steps
                  .map { |m| send(m) }
                  .flatten
                  .compact
                  .pack('C*')

        Base64.strict_encode64(bin)
      rescue NameError => e
        raise "STEPS must be defined: #{e.message}"
      end

      class << self
        # @!attribute steps
        #   An ordered list of methods to serialize the record
        #
        # @return [Array] The steps to serialize the record
        attr_accessor :steps
      end
    end
  end
end

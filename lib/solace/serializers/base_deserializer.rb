# frozen_string_literal: true

module Solace
  # !@module Serializers
  #
  # @return [Module]
  module Serializers
    # Autoload deserializers
    autoload :TransactionDeserializer, 'solace/serializers/transaction_deserializer'
    autoload :MessageDeserializer, 'solace/serializers/message_deserializer'
    autoload :InstructionDeserializer, 'solace/serializers/instruction_deserializer'
    autoload :AddressLookupTableDeserializer, 'solace/serializers/address_lookup_table_deserializer'

    # Base deserializer class
    class BaseDeserializer < Serializers::Base
      class << self
        # @!attribute STEPS
        #   An ordered list of methods to deserialize the record
        #
        # @return [Array] The steps to deserialize the record
        attr_accessor :steps

        # @!attribute RECORD_CLASS
        #   The class of the record being deserialized
        #
        # @return [Class] The class of the record
        attr_accessor :record_class
      end

      # @!attribute io
      #   The input to read bytes from.
      #
      # @return [IO, StringIO] The input to read bytes from.
      #
      # @!attribute record
      #   The record instance being deserialized.
      #
      # @return [Record] The deserialized record.
      attr_reader :io, :record

      # Initialize a new deserializer
      #
      # @param io [IO, StringIO] The input to read bytes from.
      # @return [BaseDeserializer] The new deserializer object
      def initialize(io)
        super()
        @io = io
        @record = self.class.record_class.new
      end

      # Deserializes the record
      #
      # @return [Record] The deserialized record
      def call
        self.class.steps.each { send(_1) }
        record
      end
    end
  end
end

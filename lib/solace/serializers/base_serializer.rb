# frozen_string_literal: true

module Solace
  module Serializers
    # Autoload serializers
    autoload :TransactionSerializer, 'solace/serializers/transaction_serializer'
    autoload :MessageSerializer, 'solace/serializers/message_serializer'
    autoload :InstructionSerializer, 'solace/serializers/instruction_serializer'
    autoload :AddressLookupTableSerializer, 'solace/serializers/address_lookup_table_serializer'

    # Base serializer class
    class BaseSerializer < Serializers::Base
      class << self
        # @!attribute STEPS
        #   An ordered list of methods to deserialize the record
        #
        # @return [Array] The steps to deserialize the record
        attr_accessor :steps
      end

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
    end
  end
end

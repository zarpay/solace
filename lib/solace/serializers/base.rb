# frozen_string_literal: true

module Solace
  module Serializers
    # !@class Base
    #
    # @return [Class]
    class Base
      include Solace::Utils

      # Proxy method to call the serializer and create a new instance
      #
      # @return [String] The serialized record (base64)
      def self.call(*args, **kwargs)
        new(*args, **kwargs).call
      end

      # Serializes the record
      #
      # @return [String] The serialized record (base64)
      def call
        bin = self.class::STEPS
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

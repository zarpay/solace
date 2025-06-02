# frozen_string_literal: true

module Solana
  module Serializers
    class Base
      include Solana::Utils

      class << self
        # Proxy method to call the serializer and create a new instance
        # 
        # @return [String] The serialized transaction (base64)
        def call(*args, **kwargs) 
          new(*args, **kwargs).call
        end
      end

      # Serializes the transaction
      # 
      # @return [String] The serialized transaction (base64)
      def call
        bin = self.class::SERIALIZATION_STEPS
          .map { |m| send(m) }
          .flatten
          .compact
          .pack("C*")

        Base64.strict_encode64(bin)
      rescue NameError => e
        raise "SERIALIZATION_STEPS must be defined: #{e.message}"
      end
    end
  end
end
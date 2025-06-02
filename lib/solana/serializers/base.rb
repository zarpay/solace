# frozen_string_literal: true

module Solana
  module Serializers
    class Base
      include Solana::Utils

      def self.call(*args, **kwargs) 
        new(*args, **kwargs).call
      end

      def call
        raise NotImplementedError, "Serializers must implement the call method"
      end
    end
  end
end
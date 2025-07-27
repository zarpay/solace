module Solace
  module Utils
    module CallStackUtils
      # Returns the name of the method that called the current method.
      #
      # @param depth [Integer] Number of levels to go up in the call stack (default: 1)
      # @return [Symbol, nil] The calling method name, or nil if unknown
      def calling_method_name(depth = 1)
        loc = caller_locations(depth + 1, 1)&.first
        loc&.base_label&.to_sym
      end
    end
  end
end
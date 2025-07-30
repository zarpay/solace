module Solace
  module Instructions
    class Base
      class << self
        # Must implement build method
        #
        # @return [Solace::Instruction] The instruction
        def build 
          raise NotImplementedError, "Subclasses must implement build method"
        end

        # Must implement data method
        #
        # @return [Array<Integer>] The instruction data
        def data
          raise NotImplementedError, "Subclasses must implement data method"
        end
      end
    end
  end
end

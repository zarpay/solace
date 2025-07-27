module Solace
  module Instructions
    class Base
      class << self
        # !@attribute composer
        #  An optional composer class for this instruction
        #
        # @return [Object] The composer class or nil if none is registered
        attr_reader :composer

        # Set the composer class for this instruction
        #
        # @param composer [Object] The composer class
        def has_composer(composer)
          @composer = composer
        end

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

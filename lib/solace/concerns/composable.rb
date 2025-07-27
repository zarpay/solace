# lib/solace/composable.rb
module Solace
  module Concerns
    module Composable
      # @!attribute composer
      #   The composer class for this instruction
      #
      # @return [Object] The composer class or nil if none is registered
      attr_accessor :composer
      
      # Get the registered composer class
      #
      # @return [Object] The composer class or nil if none is registered
      def get_composer_class
        self.composer || raise("No composer registered for #{self}")
      end
    
      # Create a composer instance using the registered composer class
      #
      # @param **params [Hash] Parameters to pass to the composer constructor
      # @return [Object] The composer instance
      def compose(**params)
        get_composer_class.new(**params)
      end
    end
  end
end
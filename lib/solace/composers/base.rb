module Solace
  module Composers
    class Base
      attr_reader :params, :account_context
      
      # Initialize the composer
      #
      # @param **params [Hash] Parameters to pass to the composer constructor
      def initialize(**params)
        @params = params
        @account_context = Utils::AccountContext.new
      end
      
      # Define accounts required for instruction
      #
      # @param **params [Hash] Parameters to pass to the accounts method
      # @return [Hash] Account context information
      def accounts(**params)
        raise NotImplementedError, "Subclasses must implement accounts method"
      end
      
      # Build instruction with resolved account indices
      #
      # @param indices [Hash] Account name to index mapping
      # @param **params [Hash] Parameters to pass to the instruction method
      # @return [Solace::Instruction]
      def instruction(indices:, **params)
        raise NotImplementedError, "Subclasses must implement instruction method"
      end
    end
  end
end
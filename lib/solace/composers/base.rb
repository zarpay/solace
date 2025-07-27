module Solace
  module Composers
    class Base
      # @!attribute params
      #   The params for the composer
      # 
      # @return [Hash] The parameters passed to the composer
      attr_reader :params
      
      # @!attribute account_context
      #   The account_context for the composer
      #
      # @return [Utils::AccountContext] The AccountContext instance for the composer
      attr_reader :account_context
      
      # Initialize the composer
      #
      # @param **params [Hash] Parameters to pass to the composer constructor
      def initialize(**params)
        @params = params
        @account_context = Utils::AccountContext.new
        setup_accounts
      end

      # Setup accounts required for this instruction
      #
      # @return [void]
      def setup_accounts
        raise NotImplementedError, "Subclasses must implement setup_accounts method"
      end
      
      # Build instruction with resolved account indices
      #
      # @return [void]
      def build_instruction(indices)
        raise NotImplementedError, "Subclasses must implement build_instruction method"
      end
    end
  end
end
# frozen_string_literal: true

module Solace
  module Tokens
    # Represents a Solana token with its metadata.
    #
    # A token object encapsulates the symbol and associated metadata for a Solana token. It provides
    # dynamic access to metadata attributes via method calls. This class is used within the Solace::Tokens
    # module to represent individual tokens loaded from a YAML configuration file.
    #
    # @since 0.1.0
    class Token
      attr_reader :symbol, :metadata

      # Initializes a new Token instance.
      #
      # @param symbol [String] The symbol of the token (e.g., 'USDC')
      # @param metadata [Hash] A hash containing the token's metadata attributes
      # @return [self] The initialized Token object
      def initialize(symbol, metadata)
        @symbol   = symbol
        @metadata = metadata.transform_keys(&:to_sym)
      end

      # Dynamically access metadata attributes.
      #
      # @param name [Symbol] The name of the metadata attribute
      # @return [Object] The value of the metadata attribute if it exists
      # @raise [NoMethodError] If the attribute does not exist
      def method_missing(name, *)
        return metadata[name] if metadata.key?(name)

        super
      end

      # Check if a metadata attribute exists.
      #
      # @param name [Symbol] The name of the metadata attribute
      # @param _include_private [Boolean] Whether to include private methods (not used)
      # @return [Boolean] True if the attribute exists, false otherwise
      def respond_to_missing?(name, _include_private = false)
        metadata.key?(name) || super
      end

      # Returns a string representation of the Token object.
      #
      # @return [String] The string representation of the Token
      def inspect
        "#<Solace::Token #{symbol} #{metadata.inspect}>"
      end
    end
  end
end

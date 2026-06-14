# frozen_string_literal: true

require 'yaml'

module Solace
  # Represents a Solana token with its metadata.
  #
  # A tokens object encapsulates the symbol and associated metadata for a Solana token. It provides
  # dynamic access to metadata attributes via method calls. This class is used within the Solace::Tokens
  # module to represent individual tokens loaded from a YAML configuration file.
  #
  # @example Load tokens for the 'mainnet' network
  #   Solace::Tokens.load(path: 'path/to/tokens.yml', network: 'mainnet')
  #
  # @example Access a specific token
  #   usdc = Solace::Tokens.fetch('USDC')
  #   puts usdc.address
  #
  # @example Query tokens by criteria
  #   stablecoins = Solace::Tokens.where(type: 'stablecoin')
  #
  # @since 0.1.0
  module Tokens
    autoload :Token, File.expand_path('tokens/token', __dir__)

    # Load tokens from a YAML file for a specific network
    #
    # @param path [String] Path to the YAML file
    # @param network [String, Symbol] Network name (e.g., 'mainnet', 'testnet')
    # @return [void]
    def self.load(path:, network:)
      data   = YAML.load_file(path)
      tokens = data.fetch(network.to_s) do
        raise ArgumentError, "Network '#{network}' not found in config"
      end

      # Clear previous constants and registry
      clear!

      @registry = {}

      tokens.each do |symbol, attrs|
        token                  = Solace::Tokens::Token.new(symbol, attrs)
        const_set(symbol, token)
        @registry[symbol.to_s] = token
      end
    end

    # Clear loaded tokens
    #
    # @return [void]
    def self.clear!
      (constants - [:Token]).each { |c| remove_const(c) }
      @registry = {}
    end

    # Get all loaded tokens
    #
    # @return [Array<Solace::Tokens::Token>]
    def self.all
      @registry.values
    end

    # Fetch a token by its symbol
    #
    # @param symbol [String] The symbol of the token
    # @return [Solace::Tokens::Token, nil] The token object or nil if not found
    def self.fetch(symbol)
      @registry[symbol.to_s]
    end

    # Query tokens based on criteria
    #
    # @param criteria [Hash{Symbol => Object}] Key-value pairs to filter tokens
    # @return [Array<Solace::Tokens::Token>] Array of tokens matching the criteria
    def self.where(criteria = {})
      return all if criteria.empty?

      normalized = criteria.transform_keys(&:to_sym)

      all.select do |token|
        normalized.all? { |k, v| token.metadata[k] == v }
      end
    end
  end
end

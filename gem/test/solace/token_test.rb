# frozen_string_literal: true

require 'test_helper'

describe Solace::Tokens do
  let(:constants_path) { Bundler.root.join('tmp/tokens.yml').to_s }

  before(:all) do
    File.write(constants_path, <<~YAML)
      # Devnet
      devnet:
        USDC:
          mint: usdc_address_devnet
          decimals: 6
          type: stablecoin
        USDT:
          mint: usdt_address_devnet
          decimals: 6
          type: stablecoin
        SOL:
          mint: sol_address_devnet
          decimals: 9
          type: native

      # Mainnet
      mainnet:
        USDC:
          mint: usdc_address_mainnet
          decimals: 6
          type: stablecoin
        USDT:
          mint: usdt_address_mainnet
          decimals: 6
          type: stablecoin
        SOL:
          mint: sol_address_mainnet
          decimals: 9
          type: native
    YAML
  end

  before(:each) do
    Solace::Tokens.load(path: constants_path, network: 'devnet')
  end

  describe '.load' do
    it 'loads data for the specified network' do
      Solace::Tokens.load(path: constants_path, network: 'mainnet')

      assert_equal 'usdc_address_mainnet', Solace::Tokens::USDC.mint
    end

    it 'loads all tokens from a namespaced YAML file as constants to token objects' do
      assert Solace::Tokens::SOL.is_a?(Solace::Tokens::Token)
      assert Solace::Tokens::USDC.is_a?(Solace::Tokens::Token)
      assert Solace::Tokens::USDT.is_a?(Solace::Tokens::Token)
    end

    it 'raises an error if the network is not found' do
      assert_raises(ArgumentError, "Network 'invalid_network' not found in config") do
        Solace::Tokens.load(path: constants_path, network: 'invalid_network')
      end
    end
  end

  describe '.all' do
    it 'returns all loaded tokens' do
      tokens = Solace::Tokens.all

      assert_equal 3, tokens.size
      assert(tokens.all? { |token| token.is_a?(Solace::Tokens::Token) })
    end
  end

  describe '.where' do
    it 'returns tokens matching the criteria' do
      stablecoins = Solace::Tokens.where(type: 'stablecoin')

      assert_equal 2, stablecoins.size
      assert(stablecoins.all? { |token| token.type == 'stablecoin' })
    end

    it 'returns tokens matching multiple criteria' do
      stablecoins = Solace::Tokens.where(type: 'stablecoin', decimals: 6)

      assert_equal 2, stablecoins.size
      assert(stablecoins.all? { |token| token.type == 'stablecoin' && token.decimals == 6 })
    end

    it 'returns an empty array if no tokens match the criteria' do
      non_existent = Solace::Tokens.where(type: 'non_existent')

      assert_equal 0, non_existent.size
    end
  end

  describe '.fetch' do
    it 'returns the token for the given symbol' do
      usdt = Solace::Tokens.fetch('USDT')

      assert_equal 'usdt_address_devnet', usdt.mint
    end

    it 'returns nil if the token is not found' do
      token = Solace::Tokens.fetch('NON_EXISTENT')

      assert_nil token
    end
  end

  describe 'metadata accessors' do
    it 'allows method access to token metadata' do
      usdc = Solace::Tokens::USDC

      assert_equal usdc.decimals, 6
      assert_equal usdc.type, 'stablecoin'
      assert_equal usdc.mint, 'usdc_address_devnet'
    end

    it 'raises NoMethodError for undefined metadata attributes' do
      usdc = Solace::Tokens::USDC

      assert_raises(NoMethodError) { usdc.non_existent_attribute }
    end
  end
end

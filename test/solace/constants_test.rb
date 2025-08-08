# frozen_string_literal: true

require 'bundler'
require 'test_helper'

describe Solace::Constants do
  let(:constants_path) { Bundler.root.join('tmp/constants.yml').to_s }

  describe '.load' do
    before(:all) do
      File.write(constants_path, <<~YAML)
        # Devnet
        devnet:
          my_program_id: my_program_id_devnet
          squads_program_id: squads_program_id_devnet
          usdc_mint_account: usdc_mint_account_devnet
          usdt_mint_account: usdt_mint_account_devnet
        # Mainnet
        mainnet:
          my_program_id: my_program_id_mainnet
          squads_program_id: squads_program_id_mainnet
          usdc_mint_account: usdc_mint_account_mainnet
          usdt_mint_account: usdt_mint_account_mainnet
      YAML
    end

    it 'loads all constants from a namespaced YAML file and uppercase them' do
      Solace::Constants.load(path: constants_path, namespace: 'devnet', protect_overrides: false)

      assert_equal Solace::Constants::MY_PROGRAM_ID, 'my_program_id_devnet'
      assert_equal Solace::Constants::SQUADS_PROGRAM_ID, 'squads_program_id_devnet'
      assert_equal Solace::Constants::USDC_MINT_ACCOUNT, 'usdc_mint_account_devnet'
      assert_equal Solace::Constants::USDT_MINT_ACCOUNT, 'usdt_mint_account_devnet'
    end

    it 'raises an error if a constant is already defined' do
      Solace::Constants.load(path: constants_path, namespace: 'devnet', protect_overrides: false)

      assert_raises(ArgumentError, 'Constant MY_PROGRAM_ID is already defined') do
        Solace::Constants.load(path: constants_path, namespace: 'mainnet')
      end
    end

    it 'allows overriding constants if protect_overrides is false' do
      # Reload the constants with protect_overrides set to false
      Solace::Constants.load(path: constants_path, namespace: 'mainnet', protect_overrides: false)

      # Verify that the constants have been overridden
      assert_equal Solace::Constants::MY_PROGRAM_ID, 'my_program_id_mainnet'
      assert_equal Solace::Constants::SQUADS_PROGRAM_ID, 'squads_program_id_mainnet'
      assert_equal Solace::Constants::USDC_MINT_ACCOUNT, 'usdc_mint_account_mainnet'
      assert_equal Solace::Constants::USDT_MINT_ACCOUNT, 'usdt_mint_account_mainnet'
    end
  end
end

# frozen_string_literal: true

require 'test_helper'

describe Solace::Utils::AccountContext do
  let(:context) { Solace::Utils::AccountContext.new }
  
  let(:pubkey1) { keypair1.address }
  let(:pubkey2) { keypair2.address }
  let(:keypair1) { Solace::Keypair.generate }
  let(:keypair2) { Solace::Keypair.generate }
  let(:program_id) { Solace::Constants::TOKEN_PROGRAM_ID }

  describe '#initialize' do
    it 'creates empty context' do
      assert_empty context.order
      assert_empty context.accounts
      assert_empty context.account_names
    end
  end

  describe '#add_signer' do
    before do
      context.add_signer(:payer, keypair1)
    end

    it 'adds signer account' do
      account = context.accounts[:payer]

      assert_equal true, account[:signer]
      assert_equal true, account[:writable]
      assert_equal pubkey1, account[:pubkey]
      assert_equal keypair1, account[:keypair]
    end

    it 'adds account to order' do
      assert_equal [:payer], context.order
    end

    it 'maps pubkey to account name' do
      assert_equal :payer, context.account_names[pubkey1]
    end
  end

  describe '#add_readonly_signer' do
    before do
      context.add_readonly_signer(:readonly_signer, keypair1)
    end
    
    it 'adds readonly signer account' do
      account = context.accounts[:readonly_signer]

      assert_equal true, account[:signer]
      assert_equal false, account[:writable]
      assert_equal pubkey1, account[:pubkey]
      assert_equal keypair1, account[:keypair]
    end
  end

  describe '#add_writable' do
    before do
      context.add_writable(:destination, pubkey1)
    end
    
    it 'adds writable account' do
      account = context.accounts[:destination]

      assert_nil account[:keypair]
      assert_equal false, account[:signer]
      assert_equal true, account[:writable]
      assert_equal pubkey1, account[:pubkey]
    end
  end

  describe '#add_readonly' do
    before do
      context.add_readonly(:mint, pubkey1)
    end
    
    it 'adds readonly account' do
      account = context.accounts[:mint]

      assert_nil account[:keypair]
      assert_equal false, account[:signer]
      assert_equal false, account[:writable]
      assert_equal pubkey1, account[:pubkey]
    end
  end

  describe '#add_program' do
    before do
      context.add_program(:token_program, program_id)
    end
    
    it 'adds program account' do
      account = context.accounts[:token_program]
      
      assert_nil account[:keypair]
      assert_equal false, account[:signer]
      assert_equal false, account[:writable]
      assert_equal program_id, account[:pubkey]
    end
  end

  describe 'account merging and deduplication' do
    it 'merges same pubkey with different names' do
      context.add_signer(:payer, keypair1)
      context.add_writable(:source, keypair1)
      
      # Both names should point to same account data
      assert_equal context.accounts[:payer], context.accounts[:source]
      assert_equal [:payer], context.order
      assert_equal :payer, context.account_names[pubkey1]
    end

    it 'upgrades permissions when merging accounts' do
      # Start with readonly
      context.add_readonly(:account, pubkey1)
      assert_equal false, context.accounts[:account][:writable]
      assert_equal false, context.accounts[:account][:signer]
      
      # Upgrade to writable
      context.add_writable(:account, pubkey1)
      assert_equal true, context.accounts[:account][:writable]
      assert_equal false, context.accounts[:account][:signer]
      
      # Upgrade to signer (also writable)
      context.add_signer(:account, keypair1)
      assert_equal true, context.accounts[:account][:writable]
      assert_equal true, context.accounts[:account][:signer]
      assert_equal keypair1, context.accounts[:account][:keypair]
    end

    it 'preserves existing signer status' do
      context.add_signer(:payer, keypair1)
      context.add_readonly(:payer, keypair1)
      
      assert_equal true, context.accounts[:payer][:signer]
      assert_equal true, context.accounts[:payer][:writable]
      assert_equal keypair1, context.accounts[:payer][:keypair]
    end

    it 'preserves existing writable status' do
      context.add_writable(:account, pubkey1)
      context.add_readonly(:account, pubkey1)
      
      assert_equal true, context.accounts[:account][:writable]
    end
  end

  describe '#compile' do
    before do
      context.add_signer(:payer, keypair1)
      context.add_writable(:destination, pubkey2)
      context.add_readonly(:mint, 'mint_pubkey')
      context.add_program(:token_program, program_id)
    end

    let(:compiled) { context.compile }

    it 'returns compiled account data structure' do
      assert_kind_of Hash, compiled
      assert_includes compiled.keys, :accounts
      assert_includes compiled.keys, :header
      assert_includes compiled.keys, :indices
      assert_includes compiled.keys, :signers
      assert_includes compiled.keys, :account_data
    end

    it 'compiles unique accounts in correct order' do
      accounts = compiled[:accounts]
      
      # Should have 4 unique accounts
      assert_equal 4, accounts.length
      
      # Signer should be first (Solana requirement)
      assert_equal pubkey1, accounts[0]
      
      # Other accounts follow
      assert_includes accounts, pubkey2
      assert_includes accounts, program_id
      assert_includes accounts, 'mint_pubkey'
    end

    it 'calculates correct header' do
      header = compiled[:header]
      
      # [num_required_signatures, num_readonly_signed, num_readonly_unsigned]
      assert_equal 3, header.length
      assert_equal 1, header[0]  # 1 signer (payer)
      assert_equal 0, header[1]  # 0 readonly signers
      assert_equal 2, header[2]  # 2 readonly unsigned (mint, token_program)
    end

    it 'builds correct account indices mapping' do
      indices = compiled[:indices]
      
      assert_equal 0, indices[:payer]  # Signer is first
      assert_kind_of Integer, indices[:destination]
      assert_kind_of Integer, indices[:mint]
      assert_kind_of Integer, indices[:token_program]
      
      # All indices should be unique and within range
      all_indices = indices.values
      assert_equal all_indices.uniq, all_indices
      assert all_indices.all? { |i| i >= 0 && i < 4 }
    end

    it 'extracts signers with keypairs' do
      signers = compiled[:signers]
      
      assert_equal 1, signers.length
      assert_equal keypair1, signers[0]
    end

    it 'preserves original account data' do
      account_data = compiled[:account_data]
      
      assert_equal context.accounts, account_data
    end
  end

  describe 'complex scenarios' do
    it 'handles multiple signers correctly' do
      context.add_signer(:payer, keypair1)
      context.add_readonly_signer(:authority, keypair2)
      context.add_writable(:destination, 'dest_pubkey')
      
      compiled = context.compile
      
      # Header should show 2 signers, 1 readonly signer
      header = compiled[:header]
      assert_equal 2, header[0]  # 2 signers total
      assert_equal 1, header[1]  # 1 readonly signer
      assert_equal 0, header[2]  # 0 readonly unsigned
      
      # Both signers should be in signers array
      signers = compiled[:signers]
      assert_equal 2, signers.length
      assert_includes signers, keypair1
      assert_includes signers, keypair2
    end

    it 'handles account aliases correctly' do
      context.add_signer(:payer, keypair1)
      context.add_writable(:source, keypair1)  # Same account, different name
      context.add_readonly(:destination, pubkey2)
      
      compiled = context.compile
      
      # Should only have 2 unique accounts despite 3 names
      assert_equal 2, compiled[:accounts].length
      
      # Both names should map to same index
      indices = compiled[:indices]
      assert_equal indices[:payer], indices[:source]
      
      # Different account should have different index
      refute_equal indices[:payer], indices[:destination]
    end

    it 'maintains insertion order for accounts with same permissions' do
      context.add_readonly(:mint1, 'mint1_pubkey')
      context.add_readonly(:mint2, 'mint2_pubkey')
      context.add_readonly(:mint3, 'mint3_pubkey')
      
      compiled = context.compile
      accounts = compiled[:accounts]
      
      # Should maintain order of insertion
      assert_equal 'mint1_pubkey', accounts[0]
      assert_equal 'mint2_pubkey', accounts[1]
      assert_equal 'mint3_pubkey', accounts[2]
    end

    it 'sorts signers before non-signers regardless of insertion order' do
      context.add_readonly(:mint, 'mint_pubkey')
      context.add_writable(:destination, 'dest_pubkey')
      context.add_signer(:payer, keypair1)  # Added last but should be first
      context.add_program(:program, program_id)
      
      compiled = context.compile
      accounts = compiled[:accounts]
      
      # Signer should be first despite being added last
      assert_equal pubkey1, accounts[0]
    end
  end

  describe 'edge cases' do
    it 'handles empty context compilation' do
      compiled = context.compile
      
      assert_empty compiled[:accounts]
      assert_equal [0, 0, 0], compiled[:header]
      assert_empty compiled[:indices]
      assert_empty compiled[:signers]
      assert_empty compiled[:account_data]
    end

    it 'handles single account' do
      context.add_signer(:payer, keypair1)
      
      compiled = context.compile
      
      assert_equal 1, compiled[:accounts].length
      assert_equal [1, 0, 0], compiled[:header]
      assert_equal({ payer: 0 }, compiled[:indices])
      assert_equal [keypair1], compiled[:signers]
    end

    it 'handles string and keypair pubkey formats consistently' do
      context.add_writable(:account1, pubkey1)  # String
      context.add_writable(:account2, keypair1)  # Keypair (same pubkey)
      
      compiled = context.compile
      
      # Should be treated as same account
      assert_equal 1, compiled[:accounts].length
      assert_equal compiled[:indices][:account1], compiled[:indices][:account2]
    end
  end
end

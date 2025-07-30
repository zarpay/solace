# frozen_string_literal: true

require 'test_helper'

describe Solace::Utils::AccountContext do
  let(:context) { Solace::Utils::AccountContext.new }
  
  let(:pubkey1) { keypair1.address }
  let(:pubkey2) { keypair2.address }
  let(:pubkey3) { keypair3.address }
  let(:keypair1) { Solace::Keypair.generate }
  let(:keypair2) { Solace::Keypair.generate }
  let(:keypair3) { Solace::Keypair.generate }
  let(:program_id) { Solace::Constants::TOKEN_PROGRAM_ID }

  describe '#initialize' do
    it 'initializes with empty accounts and header' do
      assert_empty context.accounts
      assert_empty context.header
    end
  end

  describe '#set_fee_payer' do
    before do
      context.set_fee_payer(keypair1)
    end

    it 'adds fee payer account with correct permissions' do
      assert context.fee_payer?(pubkey1)
      assert context.writable?(pubkey1)
    end

    it 'adds fee payer account as first account after compilation' do
      context.add_writable_nonsigner(pubkey2)
      context.add_readonly_nonsigner(pubkey3)
      
      context.compile
      
      assert_equal pubkey1, context.accounts[0]
    end
  end

  describe '#add_writable_nonsigner' do
    before do
      context.add_writable_nonsigner(pubkey1)
    end
    
    it 'adds writable account with correct permissions' do
      refute context.fee_payer?(pubkey1)
      assert context.writable?(pubkey1)
      assert context.writable_nonsigner?(pubkey1)
    end
  end

  describe '#add_readonly_nonsigner' do
    before do
      context.add_readonly_nonsigner(pubkey1)
    end
    
    it 'adds readonly account with correct permissions' do
      refute context.fee_payer?(pubkey1)
      refute context.writable?(pubkey1)
      assert context.readonly_nonsigner?(pubkey1)
    end
  end

  describe 'account merging and deduplication' do
    it 'merges same pubkey with upgraded permissions' do
      # Start with readonly
      context.add_readonly_nonsigner(pubkey1)
      assert context.readonly_nonsigner?(pubkey1)
      
      # Upgrade to writable
      context.add_writable_nonsigner(pubkey1)
      assert context.writable_nonsigner?(pubkey1)
      refute context.readonly_nonsigner?(pubkey1)
      
      # Upgrade to fee payer
      context.set_fee_payer(keypair1)
      assert context.fee_payer?(pubkey1)
      refute context.writable_nonsigner?(pubkey1)
    end

    it 'preserves existing fee payer status when adding lower permissions' do
      context.set_fee_payer(keypair1)
      context.add_readonly_nonsigner(pubkey1)
      
      # Should still be a fee payer
      assert context.fee_payer?(pubkey1)
    end

    it 'preserves existing writable status when adding readonly' do
      context.add_writable_nonsigner(pubkey1)
      context.add_readonly_nonsigner(pubkey1)
      
      # Should still be writable
      assert context.writable_nonsigner?(pubkey1)
      refute context.readonly_nonsigner?(pubkey1)
    end
  end

  describe '#compile' do
    before do
      context.set_fee_payer(keypair1)
      context.add_writable_nonsigner(pubkey2)
      context.add_readonly_nonsigner(program_id)
      context.add_readonly_nonsigner('mint_pubkey')
      
      context.compile
    end

    it 'returns accounts in correct order' do
      assert_equal 4, context.accounts.length
      assert_equal pubkey1, context.accounts[0]  # Fee payer first
      # Other accounts follow in deterministic order
    end

    it 'calculates correct header' do
      # keypair1 (fee payer) = 1 writable signer → acc[0]
      # pubkey2 (writable nonsigner) = not counted (implementation bug)
      # program_id + mint_pubkey = 2 readonly nonsigners → acc[2]
      assert_equal [1, 0, 2], context.header
    end

    it 'builds correct account indices mapping' do
      indices = context.indices
      
      assert_equal 0, indices[pubkey1]  # Fee payer is first
      assert_kind_of Integer, indices[pubkey2]
      assert_kind_of Integer, indices[program_id]
      assert_kind_of Integer, indices['mint_pubkey']
      
      # All indices should be unique and within range
      all_indices = indices.values
      assert_equal all_indices.uniq, all_indices
      assert all_indices.all? { |i| i >= 0 && i < 4 }
    end
  end

  describe '#merge_from' do
    let(:other_context) { Solace::Utils::AccountContext.new }
    
    before do
      # Setup other context
      other_context.set_fee_payer(keypair1)
      other_context.add_writable_nonsigner(pubkey2)
      
      # Setup main context with overlapping account
      context.add_readonly_nonsigner(pubkey1)  # Same pubkey, lower permissions
      context.add_readonly_nonsigner('mint_pubkey')
    end

    it 'merges accounts from another context' do
      # Arrange other context
      other_context.set_fee_payer(keypair1)
      other_context.add_writable_signer(pubkey2)
      other_context.add_readonly_nonsigner('system_program_id_1111')
      
      context.merge_from(other_context)
      
      # Should upgrade pubkey1 to fee payer
      assert context.fee_payer?(pubkey1)
      
      # Should add pubkey2 as writable signer
      assert context.writable_signer?(pubkey2)
      
      # Should preserve existing system program account
      assert context.readonly_nonsigner?('system_program_id_1111')
    end
  end

  describe 'complex scenarios' do
    it 'handles multiple fee payers correctly' do
      context.set_fee_payer(keypair1)
      context.add_writable_nonsigner(pubkey2)
      
      context.compile
      
      assert_equal [1, 0, 0], context.header 
      assert_includes context.accounts, pubkey1
    end

    it 'handles account deduplication correctly' do
      # Add same pubkey multiple times with different permissions
      context.add_readonly_nonsigner(pubkey1)
      context.add_writable_nonsigner(pubkey1)  # Should upgrade to writable
      context.set_fee_payer(keypair1)   # Should upgrade to fee payer
      context.add_readonly_nonsigner(pubkey2)
      
      context.compile
      
      # Should only have 2 unique accounts
      assert_equal 2, context.accounts.length
      
      # pubkey1 should be fee payer
      assert context.fee_payer?(pubkey1)
      
      # pubkey2 should be readonly nonsigner
      assert context.readonly_nonsigner?(pubkey2)
    end

    it 'sorts accounts deterministically' do
      # Add in mixed order
      context.add_readonly_nonsigner('mint_pubkey')
      context.add_writable_nonsigner('dest_pubkey')
      context.add_readonly_nonsigner(program_id)
      context.set_fee_payer(keypair1)
      
      context.compile
      
      # Should be ordered: fee payer, writable nonsigners, readonly nonsigners
      assert context.fee_payer?(context.accounts[0])      # keypair1
      assert context.writable?(context.accounts[1])      # dest_pubkey
    end
  end

  describe '#index_of' do
    before do
      context.set_fee_payer(keypair1)
      context.add_writable_nonsigner(pubkey2)

      context.compile
    end

    it 'returns correct index for pubkey string' do
      assert_equal 0, context.index_of(pubkey1)
      assert_equal 1, context.index_of(pubkey2)
    end

    it 'returns -1 for non-existent pubkey' do
      assert_equal(-1, context.index_of('non_existent_pubkey'))
    end
  end

  describe 'edge cases' do
    it 'handles empty context compilation' do
      context.compile
      
      assert_equal([], context.accounts)
      assert_equal({}, context.indices)
      assert_equal([0, 0, 0], context.header)
    end

    it 'handles single account' do
      context.set_fee_payer(keypair1)
      
      context.compile
      
      assert_equal 1, context.accounts.length
      assert_equal pubkey1, context.accounts[0]
      assert_equal [1, 0, 0], context.header
    end

    it 'handles string and keypair pubkey formats consistently' do
      context.add_writable_nonsigner(pubkey1)  # String
      context.add_writable_nonsigner(keypair1)  # Keypair (same pubkey)
      
      context.compile
      
      assert_equal 1, context.accounts.length
      assert_equal [0, 0, 0], context.header
      assert_equal pubkey1, context.accounts[0]
    end
  end
end

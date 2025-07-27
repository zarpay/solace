# frozen_string_literal: true

module Solace
  module Utils
    # Internal utility for managing account context in transaction building
    # with automatic deduplication and sorting
    class AccountContext
      # @!attribute order
      #   The order of accounts in the transaction
      #
      # @return [Array] The order of accounts
      attr_reader :order
      
      # @!attribute accounts
      #   The accounts in the transaction
      #
      # @return [Hash] The accounts
      attr_reader :accounts
      
      # @!attribute account_names
      #   The names of accounts in the transaction
      #
      # @return [Hash] The names of accounts
      attr_reader :account_names
      
      def initialize
        @order = []
        @accounts = {}
        @account_names = {}  # pubkey -> primary_name mapping
      end

      # Add a signer account
      #
      # @param name [String] The name of the signer account
      # @param keypair [Solace::Keypair] The keypair of the signer account
      def add_signer(name, keypair)
        merge_account(name, keypair, signer: true, writable: true, keypair: keypair)
      end
      
      # Add a readonly signer account
      #
      # @param name [String] The name of the readonly signer account
      # @param keypair [Solace::Keypair] The keypair of the readonly signer account
      def add_readonly_signer(name, keypair)
        merge_account(name, keypair, signer: true, writable: false, keypair: keypair)
      end
      
      # Add a writable account
      #
      # @param name [String] The name of the writable account
      # @param pubkey [String|Solace::PublicKey] The public key of the writable account
      def add_writable(name, pubkey)
        merge_account(name, pubkey, signer: false, writable: true, keypair: nil)
      end
      
      # Add a readonly account
      #
      # @param name [String] The name of the readonly account
      # @param pubkey [String|Solace::PublicKey] The public key of the readonly account
      def add_readonly(name, pubkey)
        merge_account(name, pubkey, signer: false, writable: false, keypair: nil)
      end
      
      # Add a program account
      #
      # @param name [String] The name of the program account
      # @param program_id [String] The program ID of the program account
      def add_program(name, program_id)
        merge_account(name, program_id, signer: false, writable: false, keypair: nil)
      end
      
      # Compile accounts into final format
      # 
      # Gets unique accounts and sorts them in the following order:
      #   - Signers first (Solana requirement)
      #   - Then writable accounts
      #   - Then readonly accounts
      #
      # @return [Hash] The compiled accounts
      def compile
        unique_accounts = @order
          .map { |name| @accounts[name].merge(name: name) }
          .uniq { |acc| acc[:pubkey] }
          .sort_by { |acc| [acc[:signer] ? 0 : 1, @order.index(acc[:name])] }

        {
          account_data: @accounts,
          indices: build_indices(unique_accounts),
          header: calculate_header(unique_accounts),
          accounts: unique_accounts.map { |acc| acc[:pubkey] },
          signers: unique_accounts.select { |acc| acc[:keypair] }.map { |acc| acc[:keypair] },
        }
      end
      
      private

      # Add or merge an account into the context
      #
      # @param name [String] The name of the account
      # @param pubkey [String|Solace::PublicKey] The public key of the account
      # @param keypair [Solace::Keypair] The keypair of the account
      # @param signer [Boolean] Whether the account is a signer
      # @param writable [Boolean] Whether the account is writable
      def merge_account(
        name,
        pubkey,
        keypair:,
        signer:,
        writable:
      )
        pubkey_str = resolve_pubkey(pubkey)
        existing_name = @account_names[pubkey_str]
        # If the account does not exist, add it
        if existing_name.nil?
          add_account(name, pubkey_str, signer, writable, keypair)
        else
          update_account(existing_name, signer, writable, keypair)
          update_aliases(existing_name, name)
        end
        
        self
      end

      # Adds a name alias to an existing account
      #
      # @param existing_name [String] The name of the existing account to add an alias to
      # @param alias_name [String] The alias name to add
      def update_aliases(existing_name, alias_name)
        return unless alias_name != existing_name
        
        @accounts[alias_name] = @accounts[existing_name]
      end

      # Adds a new account to the account context
      #
      # @param name [String] The name of the account
      # @param pubkey_str [String] The public key of the account
      # @param signer [Boolean] Whether the account is a signer
      # @param writable [Boolean] Whether the account is writable
      # @param keypair [Solace::Keypair] The keypair of the account
      def add_account(name, pubkey_str, signer, writable, keypair)
        @accounts[name] = {
          pubkey: pubkey_str,
          signer: signer,
          keypair: keypair,
          writable: writable,
        }
        @account_names[pubkey_str] = name
        @order << name
      end

      # Updates an existing account in the account context
      #
      # @param existing_name [String] The name of the existing account to update
      # @param signer [Boolean] Whether the account is a signer
      # @param writable [Boolean] Whether the account is writable
      # @param keypair [Solace::Keypair] The keypair of the account
      def update_account(existing_name, signer, writable, keypair)
        existing = @accounts[existing_name]

        @accounts[existing_name].merge!({
          # If an existing account is a signer, then it must be a signer in all contexts. If it
          # is not an existing signer in one context, then the new context should be used to set
          # the signer flag.
          signer: existing[:signer] || signer,
          keypair: existing[:keypair] || keypair,
          writable: existing[:writable] || writable
        })
      end

      # Resolve the pubkey from a Solace::PublicKey or String
      #
      # @param pubkey [String|Solace::PublicKey] The pubkey to resolve
      # @return [String] The resolved pubkey
      def resolve_pubkey(pubkey)
        pubkey.is_a?(String) ? pubkey : pubkey.address
      end
      
      # Calculate the header for the transaction
      #
      # @note The header is an array of three integers:
      #   - The number of signers
      #   - The number of readonly signers
      #   - The number of readonly unsigned accounts
      #
      # @param accounts [Array] The accounts to calculate the header for
      # @return [Array] The header for the transaction
      def calculate_header(accounts)
        [
          accounts.count { |acc| acc[:signer] },
          accounts.count { |acc| acc[:signer] && !acc[:writable] },
          accounts.count { |acc| !acc[:signer] && !acc[:writable] }
        ]
      end

      # Build indices for the accounts
      #
      # @param accounts [Array] The accounts to build indices for
      # @return [Hash] The indices for the accounts
      def build_indices(accounts)
        # Build mapping from account names to their indices in the final accounts array
        indices = {}
        
        accounts.each_with_index do |acc, idx|
          # Map all names that point to this pubkey to this index
          @accounts.each do |name, data|
            indices[name] = idx if data[:pubkey] == acc[:pubkey]
          end
        end
        
        indices
      end
    end
  end
end

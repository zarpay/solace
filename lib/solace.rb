# frozen_string_literal: true

# Solace is a Ruby gem for interacting with the Solana blockchain.
#
# This gem provides a comprehensive toolkit for building, signing, and sending
# transactions to Solana RPC nodes. It includes utilities for managing keypairs,
# composing complex instructions, serializing data, and interacting with
# on-chain programs like the System Program, SPL Token Program, and Associated
# Token Account Program.
#
# The gem is designed to be modular and extensible, with clear separation between
# low-level primitives (instructions, serializers) and high-level abstractions
# (composers, programs).
#
# @example Basic usage
#   # Connect to a Solana RPC node
#   connection = Solace::Connection.new('https://api.mainnet-beta.solana.com')
#
#   # Generate a keypair
#   keypair = Solace::Keypair.generate
#
#   # Check balance
#   balance = connection.get_balance(keypair.public_key)
#
# @see https://docs.solana.com/
# @see https://github.com/zarpay/solace
# @author Sebastian Scholl
# @since 0.0.1
module Solace; end

# Version
require_relative 'solace/version'

# Helpers
require_relative 'solace/errors'
require_relative 'solace/constants'
require_relative 'solace/connection'
require_relative 'solace/utils/codecs'
require_relative 'solace/utils/pda'
require_relative 'solace/utils/account_context'
require_relative 'solace/utils/curve25519_dalek'
require_relative 'solace/concerns/binary_serializable'

# Tokens
require_relative 'solace/tokens'

# Serializers
require_relative 'solace/serializers/base_serializer'
require_relative 'solace/serializers/base_deserializer'

# Primitives
require_relative 'solace/keypair'
require_relative 'solace/public_key'
require_relative 'solace/transaction'
require_relative 'solace/message'
require_relative 'solace/instruction'
require_relative 'solace/address_lookup_table'
require_relative 'solace/transaction_composer'

# Base Classes (Abstract classes)
require_relative 'solace/programs/base'
require_relative 'solace/composers/base'

# Composers
Dir[File.join(__dir__, 'solace/composers', '**', '*.rb')].each { |file| require file }

# Instructions (Builders)
Dir[File.join(__dir__, 'solace/instructions', '**', '*.rb')].each { |file| require file }

# Programs
require_relative 'solace/programs/token_program_base'
require_relative 'solace/programs/spl_token'
require_relative 'solace/programs/token_2022'
require_relative 'solace/programs/associated_token_account'

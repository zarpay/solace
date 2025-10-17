# frozen_string_literal: true

# 🏷️ Version
require_relative 'solace/version'

# 🛠️ Helpers
require_relative 'solace/errors'
require_relative 'solace/constants'
require_relative 'solace/connection'
require_relative 'solace/utils/codecs'
require_relative 'solace/utils/pda'
require_relative 'solace/utils/account_context'
require_relative 'solace/utils/curve25519_dalek'
require_relative 'solace/concerns/binary_serializable'

# 🪙 Tokens
require_relative 'solace/tokens'

# ✨ Serializers
require_relative 'solace/serializers/base_serializer'
require_relative 'solace/serializers/base_deserializer'

# 🧬 Primitives
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

# 📦 Composers
#
# Glob require all composers
Dir[File.join(__dir__, 'solace/composers', '**', '*.rb')].each { |file| require file }

# 📦 Instructions (Builders)
#
# Glob require all instructions
Dir[File.join(__dir__, 'solace/instructions', '**', '*.rb')].each { |file| require file }

# 📦 Programs
require_relative 'solace/programs/spl_token'
require_relative 'solace/programs/associated_token_account'

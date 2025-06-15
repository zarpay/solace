# frozen_string_literal: true

# 🏷️ Version
require_relative 'solace/version'

# 🛠️ Helpers
require_relative 'solace/constants'
require_relative 'solace/connection'
require_relative 'solace/utils/codecs'
require_relative 'solace/utils/pda'
require_relative 'solace/utils/curve25519_dalek'
require_relative 'solace/concerns/binary_serializable'

# ✨ Serializers
require_relative 'solace/serializers/base'
require_relative 'solace/serializers/base_serializer'
require_relative 'solace/serializers/base_deserializer'

# Base classes
require_relative 'solace/serializable_record'

# 🧬 Primitives
require_relative 'solace/keypair'
require_relative 'solace/public_key'
require_relative 'solace/transaction'
require_relative 'solace/message'
require_relative 'solace/instruction'
require_relative 'solace/address_lookup_table'

# 📦 Instructions (Builders)
require_relative 'solace/instructions/transfer_instruction'
require_relative 'solace/instructions/transfer_checked_instruction'



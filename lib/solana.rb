# frozen_string_literal: true

# 🏷️ Version
require_relative 'solana/version'

# 🛠️ Helpers
require_relative 'solana/constants'
require_relative 'solana/connection'
require_relative 'solana/utils/codecs'
require_relative 'solana/utils/keypair'
require_relative 'solana/concerns/binary_serializable'

# ✨ Serializers
require_relative 'solana/serializers/base'
require_relative 'solana/serializers/base_serializer'
require_relative 'solana/serializers/base_deserializer'

# Base classes
require_relative 'solana/serializable_record'

# 🧬 Transactions
require_relative 'solana/transaction'
require_relative 'solana/message'
require_relative 'solana/instruction'
require_relative 'solana/address_lookup_table'

# 📦 Instructions (Builders)
require_relative 'solana/instructions/transfer_instruction'


# encoding: ASCII-8BIT
# frozen_string_literal: true

require 'base64'
require 'rbnacl'
require 'base58'
require 'stringio'

require 'test_helper'

# =============================
# 🧩 Legacy Transaction
# =============================
#
# Base64 encoded legacy transaction
#
# rubocop:disable Layout/LineLength
serialized_transaction = 'AcaMpLmLt94VN+8I6G5Gl4fkr8yAawMrfDLgHzllHPuJh9UrMwPGFg8f1+XIPCJ++1gQhUm2iqykguCCW8yLXAEBAAMFrBYKcNpllQ32WLoMCd2PaL1ByibWi05UEFONRtCO9tN/rqFhq+q8I5Y2Z+0JFrZ3yFicOGyV+ehkL4SjrHfiJQan1RcZLwqvxvJl4/t3zHragsUp0L47E24tAFUgAAAABqfVFxjHdMkoVmOYaR1etoteuKObS21cc1VbIQAAAAAHYUgdNXR0u3xNdiTr072z2DVec9EQQ/wNo1OAAAAAAGCuTeqVWHTH4S+Zvy3yupOkl9cHQQW+HrLw7BH9zvaHAQQEAQIDADUCAAAAAQAAAAAAAAADAAAAAAAAAMKSUZmaRJYqMQtNQ+kLV4M8Ln+LqIHtLf+eM3ERhdG3AA=='
# rubocop:enable Layout/LineLength

# Step 1: Base64 decode
transaction_bytes = Base64.decode64(serialized_transaction)

# Step 2: Create a byte stream
io = StringIO.new(transaction_bytes)

# Step 3: Find the number of signatures
num_signatures, = Solace::Utils::Codecs.decode_compact_u16(io)
puts "Number of signatures: #{num_signatures}"

# Step 4: Extract the signatures
signatures = Array.new(num_signatures).map { io.read(64) }
puts "Signatures: #{signatures}"

# Step 5: Extract the message header
message_header = io.read(3).bytes
puts 'Message header:'
puts "  numRequiredSignatures: #{message_header[0]}"
puts "  numReadonlySignedAccounts: #{message_header[1]}"
puts "  numReadonlyUnsignedAccounts: #{message_header[2]}"

# Step 6: Extract the number of account keys
num_accounts, = Solace::Utils::Codecs.decode_compact_u16(io)
puts "Number of account keys: #{num_accounts}"

# Step 7: Extract the account keys
accounts = Array.new(num_accounts).map { io.read(32) }
puts "Account keys: #{accounts}"

# Step 8: Extract the recent blockhash
recent_blockhash = Solace::Utils::Codecs.bytes_to_base58(io.read(32).bytes)
puts "Recent blockhash: #{recent_blockhash}"

# Step 9: Extract the number of instructions
num_instructions, = Solace::Utils::Codecs.decode_compact_u16(io)
puts "Number of instructions: #{num_instructions}"

# Step 10: Extract the instructions
instructions = Array.new(num_instructions).map do
  # 10.1: Extract instruction index
  program_instruction_index = io.read(1).ord
  puts "Program instruction index: #{program_instruction_index}"

  # 10.2: Extract number of accounts
  num_accounts_in_instruction, = Solace::Utils::Codecs.decode_compact_u16(io)
  puts "Number of accounts: #{num_accounts_in_instruction}"

  # 10.3: Extract accounts
  accounts_in_instruction = Array.new(num_accounts_in_instruction).map { io.read(1).ord }
  puts "Accounts: #{accounts_in_instruction}"

  # 10.4: Extract instruction data
  instruction_data_length, = Solace::Utils::Codecs.decode_compact_u16(io)
  puts "Instruction data length: #{instruction_data_length}"

  # 10.5: Extract instruction data
  instruction_data = io.read(instruction_data_length).unpack('C*')
  puts "Instruction data: #{instruction_data}"

  # 10.6: Return instruction
  [
    program_instruction_index,
    num_accounts_in_instruction,
    accounts_in_instruction,
    instruction_data_length,
    instruction_data
  ]
end
puts "Instructions: #{instructions}"

# 11: Confirm end of message
puts "End of message: #{io.eof?}"

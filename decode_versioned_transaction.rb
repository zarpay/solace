# encoding: ASCII-8BIT

require 'base64'
require 'rbnacl'
require 'base58'
require 'stringio'

require_relative 'lib/solana/utils/codecs'
Codecs = Solana::Utils::Codecs

# =============================
# 🧩 Versioned Transaction
# =============================
# 
# Base64 encoded versioned transaction
# 
serialized_transaction = 'Acgu9eEm+Vemca/5lLQJbSJYa0YvkB5bGYafvo4thl6lHNYsSAG7sVh4KAX+k2zPl1gf4zd0Yd9Ds+UVOkIhvwWAAQAEDpkYZngZ374Y0pb6toNS8GHchmk84eLPpT4FJYf5crqomSd1qmAcQwzxZ+k/CeilJsmeji0PQ1cYjpPgihQaOIWIBErEGNasI3hrll4pKZsGHXknGG0+wErI4I5gt02GfJYlqLPaiX4sQV4FMW9kLNv5yW7ehfQRK8XbAqgyNWMlNf7CHxePVFUrXDi1BMb/4ybhol6hmYY5qaC5PldZqTEtApC6Uq9mdQdfYV0bL+7LTUAhN/sLOh2FVZeB3rqseUgWJ/Wlr2SJc6B3X4zsauwJo1l30cYqGje+BVlW8rQ+2mxPsy/Mq5zYLYsZPpxwGo2Mf6HYD38wsqhDpTRfMvb5Cbin+fF73r0gMfSNlfSaAnV+fOpSFHPQN5Yq0KXSELfiD4hBX0flO2syRT6ZYt+fhAzZmL93ET+6qG9NydzRAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADBkZv5SEXMv/srbpyw5vnvIzlu8X3EmssQ5s6QAAAAMKC3ZljbddWFnVt++HEh8V+9bue8NoWVHq2eCijyFuLBHnVLe2/a8Xs0J2EU0o0rqWXUEOzb9ArJGULtYRDWVwqyfBc4wPKEDwZ+J83/G1LSd0aTRUzQ+x3nDrAPv64oQQLAAkDAQAAAAAAAAALAAUCY2sOAA05IwAgMS8eLSwdHAggAAggADAKIzIuIiMAEB8OCA8BAQEkIiMAGQIaHxsHBwcrIiMABAIJIAUDBgYMLOUXy5d6460qAAQAAAACFwACEQACEQACEQEfdAAAAAAAAB90AAAAAAAAAAAADRkjAB8mIyclAB8TEiEUESgjKikAIRgXHxYVJOUXy5d6460qAAIAAAACAwIDRzkeAAAAAABHOR4AAAAAAAAAAAZeksiuGUD29Evnx5+b5Awe13wncsSmQU2U1qFnaqfiWANrbJoDbQRpB8dTfmoXCYp/6NAuhjfAkYGFdrwum0jfX4IP+UDTmQwExMbFwwPKyMc9eI6loMOfhEUBficrajwPaSQFTUllI+ZuBSUzy0HtbARQT05NA0lMS9LDB68Y9BoPcKBD37erv38IqCugyHrQuvRdzSVNl2UNA9nd4AHhO9l9gy3odcj1w3FZTmZWYdQ2gP9C6xGhBBeyH+n2swMDW1pXB15YYVZfXGMpc7pKAgpBMfko96SFVmoW5yI6moN3eGQnlJmiZwZQLAOgkUoA'

# Step 1: Base64 decode
transaction_bytes = Base64.decode64(serialized_transaction)

# Step 2: Create a byte stream
io = StringIO.new(transaction_bytes)

# Step 3: Find the number of signatures
num_signatures, _ = Codecs.decode_compact_u16(io)
puts "Number of signatures: #{num_signatures}"

# Step 4: Extract the signatures
signatures = []
num_signatures.times { signatures << io.read(64) }
puts "Signatures: #{signatures}"

# Step 5: Check version prefix
version_prefix = io.read(1).unpack1("C")
# io.seek(-1, IO::SEEK_CUR)

puts "Version prefix: #{version_prefix & 0x7F}" # Should be 0

# Step 6: Extract the message header
message_header = io.read(3).bytes
puts "Message header:"
puts "  numRequiredSignatures: #{message_header[0]}"
puts "  numReadonlySignedAccounts: #{message_header[1]}"
puts "  numReadonlyUnsignedAccounts: #{message_header[2]}"

# Step 7: Extract the number of account keys
num_accounts, _ = Codecs.decode_compact_u16(io)
puts "Number of account keys: #{num_accounts}"

# Step 8: Extract the account keys
accounts = []
num_accounts.times { accounts << io.read(32) }
puts "Account keys: #{accounts}"

# Step 9: Extract the recent blockhash
recent_blockhash = Codecs.bytes_to_base58(io.read(32).bytes)
puts "Recent blockhash: #{recent_blockhash}"

# Step 10: Extract the number of instructions
num_instructions, _ = Codecs.decode_compact_u16(io)
puts "Number of instructions: #{num_instructions}"

# Step 11: Extract the instructions
instructions = Array.new(num_instructions).map do
  # 11.1: Extract instruction index
  program_instruction_index = io.read(1).ord
  puts "Program instruction index: #{program_instruction_index}"

  # 11.2: Extract number of accounts
  num_accounts_in_instruction, _ = Codecs.decode_compact_u16(io)
  puts "Number of accounts: #{num_accounts_in_instruction}"

  # 11.3: Extract accounts
  accounts_in_instruction = []
  num_accounts_in_instruction.times { accounts_in_instruction << io.read(1).ord }
  puts "Accounts: #{accounts_in_instruction}"

  # 11.4: Extract instruction data
  instruction_data_length, _ = Codecs.decode_compact_u16(io)
  puts "Instruction data length: #{instruction_data_length}"

  # 11.5: Extract instruction data
  instruction_data = io.read(instruction_data_length).unpack("C*")
  puts "Instruction data: #{instruction_data}"

  # 11.6: Return instruction
  [
    program_instruction_index,
    num_accounts_in_instruction,
    accounts_in_instruction,
    instruction_data_length,
    instruction_data
  ]
end
puts "Instructions: #{instructions}"

# Step 12: Extract address table lookup
num_addresses, _ = Codecs.decode_compact_u16(io)
puts "Number of addresses: #{num_addresses}"

addresses = Array.new(num_addresses).map do
  account_key = Codecs.bytes_to_base58 io.read(32).bytes
  
  num_writable, _ = Codecs.decode_compact_u16(io)
  writable_indexes = io.read(num_writable).unpack("C*")

  num_readonly, _ = Codecs.decode_compact_u16(io)
  readonly_indexes = io.read(num_readonly).unpack("C*")

  [account_key, writable_indexes, readonly_indexes]
end
puts "Addresses: #{addresses}"

# Step 13: Confirm end of message
unless io.eof?
  remaining = io.read
  puts "WARNING: Not at end of message! Remaining bytes: #{remaining.bytes.inspect}"
end


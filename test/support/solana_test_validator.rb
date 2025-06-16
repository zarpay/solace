
# Spins up a Solana test validator before tests and tears it down after all tests have run.

SOLANA_VALIDATOR_CMD = "solana-test-validator"
SOLANA_VALIDATOR_LOG = "/tmp/solana-test-validator.log"
SOLANA_VALIDATOR_ERR = "/tmp/solana-test-validator.err.log"

# If the validator is already running, return. This check will not
# work on certain systems, but it's better than nothing.
@validator_pid = `ps | grep 'solana-test-val'`.strip

return unless @validator_pid.empty?

@started_validator = true

# Spawn the validator in a child process
@solana_validator_pid = Process.spawn(
  SOLANA_VALIDATOR_CMD, 
  out: SOLANA_VALIDATOR_LOG, 
  err: SOLANA_VALIDATOR_ERR
)

puts "[SolanaTestValidator] Validator started on PID #{@solana_validator_pid}."

def validator_started?
  Solace::Connection.new.get_latest_blockhash
  true
rescue Errno::ECONNREFUSED
  false
end

while !validator_started?
  puts "[SolanaTestValidator] Waiting for first blockhash..."  
  sleep 1
end

# Stop the validator after all tests have run
Minitest.after_run do
  # Only if the validator was started by us should we stop it
  return unless @started_validator

  Process.kill("TERM", @solana_validator_pid)
  Process.wait(@solana_validator_pid)

  puts "\n[SolanaTestValidator] Validator stopped."
end


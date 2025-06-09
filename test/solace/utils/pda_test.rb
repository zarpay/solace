require 'test_helper'

describe Solace::Utils::PDA do
  describe '#find_program_address' do
    # The expected PDA addresses and their corresponding seeds and program IDs. These
    # values were generated using the Solana kit at https://solana.com/docs/core/pda
    let(:pda_addresses) do
      [
        {
          pda_address: 'CZ7UF6XZRvp9EQ7Wo3yxzxJZrJWpUuYrdFgGt7svMBXy',
          bump: 255,
          seeds: ['MySeed'],
          program_id: 'MyProgram1111111111111111111111111111111111'
        },
        {
          pda_address: 'B9sP84TpodjZg6xPqswcHRaE4P3hEYVGegrAAMs1hjMf',
          bump: 255,
          seeds: [
            '8PpJz4e1e1UnR5QdExVnMrf2SRQ9vBNGdfZeyZkKo4HT', # owner
            'TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA', # token
            '8PpJz4e1e1UnR5QdExVnMrf2SRQ9vBNGdfZeyZkKo4HT' # mint
          ],
          program_id: 'ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA5Nif'
        }
      ]
    end 
    
    it 'finds the PDA address and bump' do
      pda_addresses.each do |pda_address|
        address, bump = Solace::Utils::PDA.find_program_address(
          pda_address[:seeds],
          pda_address[:program_id]
        )

        assert_equal pda_address[:bump], bump
        assert_equal pda_address[:pda_address], address
      end
    end
  end
end

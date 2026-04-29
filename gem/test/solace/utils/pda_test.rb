# frozen_string_literal: true

require 'test_helper'

describe Solace::Utils::PDA do
  describe '#find_program_address' do
    # The expected PDA addresses and their corresponding seeds and program IDs. These
    # values were generated using the Solana kit at https://solana.com/docs/core/pda
    let(:pda_addresses) do
      [
        {
          # My Program PDA
          pda_address: 'CZ7UF6XZRvp9EQ7Wo3yxzxJZrJWpUuYrdFgGt7svMBXy',
          bump: 255,
          seeds: %w[MySeed],
          program_id: 'MyProgram1111111111111111111111111111111111'
        },
        {
          # ZAR Escrow PDA devnet
          pda_address: '4wBgoYaMWu9yVAoLp3MqTbjtGLbLrK7HGkUhAfag64xv',
          bump: 255,
          seeds: %w[
            escrow_deposit
            FRgEYVCueFxFeqq3vP7WrHgvnz8YRoBDz2SshoLz8U7Q
          ],
          program_id: '5Y3yGEVqbZJDn41YnVETMbTt8yq4HKreVkS6X3cxErvH'
        },
        {
          # Associated Token Account PDA
          pda_address: 'GeQiE41zi17u5ENDEWetKSBkrgVneZYo6qCLbtyDSVbZ',
          bump: 255,
          seeds: %w[
            7uKbd92U6LgAvXGvFgMAmgmgG1FmqwzBRsBN6KKcE2R4
            TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA
            EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v
          ],
          program_id: 'ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL'
        },
        {
          # Off Curve with Bump address
          pda_address: '3J9UVhG3K8To1CCwFjstWRDyFzhu2ytehrygKgNemwk9',
          bump: 253,
          seeds: %w[FindRandomBump_],
          program_id: '5Y3yGEVqbZJDn41YnVETMbTt8yq4HKreVkS6X3cxErvH'
        },
        {
          # Another Off Curve with Bump address
          pda_address: 'CWSM8UbEALk2MAxbkg5tNVMXia9F2Lq2fXD6e5iHFn5n',
          bump: 251,
          seeds: [
            'wallet_account',
            102,
            'EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v'
          ],
          program_id: '3LkGTjNsF2zWc2ddBPHYyEJJZKqbdHJDgfjztxnjwL5R'
        },
        {
          # Another Off Curve with Bump address
          pda_address: 'G3Zss7LJgpAFj1wpT9aT4FrkRd47Hso6tUEMJas4USpR',
          bump: 245,
          seeds: [
            '$user_account_id',
            [374],
            'Rq7zLIpy0ETAgOMuWEUzD3Ic'
          ],
          program_id: '3LkGTjNsF2zWc2ddBPHYyEJJZKqbdHJDgfjztxnjwL5R'
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

# frozen_string_literal: true

module Solace
  module Instructions
    module AddressLookupTableProgram
      # Instruction for appending addresses to an existing address lookup table.
      #
      # Newly added addresses become usable one slot after the extend lands.
      #
      # @example Build an ExtendLookupTable instruction
      #   instruction = Solace::Instructions::AddressLookupTableProgram::ExtendLookupTableInstruction.build(
      #     addresses:            [recipient1, recipient2],
      #     program_index:        4,
      #     table_index:          1,
      #     authority_index:      0,
      #     payer_index:          0,
      #     system_program_index: 3
      #   )
      #
      # @since 0.1.7
      class ExtendLookupTableInstruction
        # Instruction discriminator for ExtendLookupTable (u32 LE)
        INSTRUCTION_ID = [2, 0, 0, 0].freeze

        # Builds a Solace::Instruction for extending a lookup table
        #
        # @param addresses [Array<#to_s>] The addresses to append to the table
        # @param program_index [Integer] Index of the lookup table program
        # @param table_index [Integer] Index of the table account (writable)
        # @param authority_index [Integer] Index of the table authority (signer)
        # @param payer_index [Integer] Index of the rent payer (writable signer)
        # @param system_program_index [Integer] Index of the system program
        # @return [Solace::Instruction]
        def self.build(
          addresses:,
          program_index:,
          table_index:,
          authority_index:,
          payer_index:,
          system_program_index:
        )
          Instruction.new.tap do |ix|
            ix.program_index = program_index
            ix.accounts      = [table_index, authority_index, payer_index, system_program_index]
            ix.data          = data(addresses)
          end
        end

        # Instruction data for an extend lookup table instruction
        #
        # The BufferLayout is:
        #   - [Instruction discriminator (4 bytes, u32 LE)]
        #   - [Number of addresses (8 bytes, u64 LE)]
        #   - [Addresses (32 bytes each)]
        #
        # The address vector uses a u64 length prefix (bincode), not the u32
        # Borsh prefix of {Utils::Codecs.encode_vec_pubkeys}.
        #
        # @param addresses [Array<#to_s>] The addresses to append
        # @return [Array<Integer>]
        def self.data(addresses)
          INSTRUCTION_ID +
            Utils::Codecs.encode_le_u64(addresses.length).bytes +
            addresses.flat_map { |address| Utils::Codecs.encode_pubkey(address) }
        end
      end
    end
  end
end

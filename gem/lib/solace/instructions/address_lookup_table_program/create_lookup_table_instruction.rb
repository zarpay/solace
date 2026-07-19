# frozen_string_literal: true

module Solace
  module Instructions
    # The AddressLookupTableProgram module contains instruction builders for the
    # Address Lookup Table program.
    #
    # Address lookup tables let a versioned (v0) transaction reference accounts by
    # a compact table index instead of a full 32-byte key, so a single transaction
    # can touch far more accounts than the legacy format allows.
    #
    # @see https://docs.solana.com/developing/lookup-tables
    # @since 0.1.8
    module AddressLookupTableProgram
      # Instruction for creating a new (uninitialized) address lookup table.
      #
      # The table's address is a program-derived address of `[authority, recent_slot]`;
      # the caller supplies the derived address and its bump seed.
      #
      # @example Build a CreateLookupTable instruction
      #   instruction = Solace::Instructions::AddressLookupTableProgram::CreateLookupTableInstruction.build(
      #     recent_slot:          123,
      #     bump:                 254,
      #     program_index:        4,
      #     table_index:          1,
      #     authority_index:      0,
      #     payer_index:          0,
      #     system_program_index: 3
      #   )
      #
      # @since 0.1.8
      class CreateLookupTableInstruction
        # Instruction discriminator for CreateLookupTable (u32 LE)
        INSTRUCTION_ID = [0, 0, 0, 0].freeze

        # Builds a Solace::Instruction for creating a lookup table
        #
        # @param recent_slot [Integer] The slot used to derive the table address
        # @param bump [Integer] The bump seed for the table's program-derived address
        # @param program_index [Integer] Index of the lookup table program
        # @param table_index [Integer] Index of the (uninitialized) table account
        # @param authority_index [Integer] Index of the table authority (signer)
        # @param payer_index [Integer] Index of the rent payer (writable signer)
        # @param system_program_index [Integer] Index of the system program
        # @return [Solace::Instruction]
        def self.build(
          recent_slot:,
          bump:,
          program_index:,
          table_index:,
          authority_index:,
          payer_index:,
          system_program_index:
        )
          Instruction.new.tap do |ix|
            ix.program_index = program_index
            ix.accounts      = [table_index, authority_index, payer_index, system_program_index]
            ix.data          = data(recent_slot, bump)
          end
        end

        # Instruction data for a create lookup table instruction
        #
        # The BufferLayout is:
        #   - [Instruction discriminator (4 bytes, u32 LE)]
        #   - [Recent slot (8 bytes, u64 LE)]
        #   - [Bump seed (1 byte)]
        #
        # @param recent_slot [Integer] The slot used to derive the table address
        # @param bump [Integer] The bump seed
        # @return [Array<Integer>]
        def self.data(recent_slot, bump)
          INSTRUCTION_ID +
            Utils::Codecs.encode_le_u64(recent_slot).bytes +
            [bump]
        end
      end
    end
  end
end

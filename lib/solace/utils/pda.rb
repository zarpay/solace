# encoding: ASCII-8BIT
# frozen_string_literal: true

require 'digest'

module Solace
  module Utils
    # Module for generating program addresses
    #
    # This module provides methods for generating program addresses from seeds and program IDs. It interfaces
    # with the Curve25519 Dalek library to check if a point is on the curve. It also provides a method for
    # converting seeds to bytes and a method for checking if a string looks like a base58 address.
    #
    # @see Solace::Utils::Curve25519Dalek
    # @since 0.0.1
    module PDA
      # InvalidPDAError is an error raised when an invalid PDA is generated
      class InvalidPDAError < StandardError; end

      # !@attribute PDA_MARKER
      # PDA_MARKER is the marker used in PDA calculations
      PDA_MARKER = 'ProgramDerivedAddress'

      # !@attribute MAX_BUMP_SEED
      # The maximum seed value for PDA calculations
      MAX_BUMP_SEED = 255

      # Finds a valid program address by trying different seeds
      #
      # @example Find a PDA with bump seed
      #   seeds = ['metadata', mint_address, 'edition']
      #   program_id = 'metaqbxxUerdq28cj1RbAWkYQm3ybzjb6a8bt518x1s'
      #
      #   address, bump = Solace::Utils::PDA.find_program_address(seeds, program_id)
      #
      # @param seeds [Array] The seeds to use in the calculation
      # @param program_id [String] The program ID to use in the calculation
      # @return [Array] The program address and bump seed
      # @raise [InvalidPDAError] If no valid program address is found
      def self.find_program_address(seeds, program_id)
        MAX_BUMP_SEED.downto(0) do |bump|
          address = create_program_address(seeds + [bump], program_id)
          return [address, bump]
        rescue InvalidPDAError
          next
        end

        raise 'Unable to find a valid program address'
      end

      # Creates a program address from seeds and program ID
      #
      # @param seeds [Array] The seeds to use in the calculation
      # @param program_id [String] The program ID to use in the calculation
      # @return [String] The program address
      # @raise [InvalidPDAError] If the program address is invalid
      def self.create_program_address(seeds, program_id)
        seed_bytes = seeds.map { |seed| seed_to_bytes(seed) }.flatten

        program_id_bytes = Solace::Utils::Codecs.base58_to_bytes(program_id)

        combined = seed_bytes + program_id_bytes + PDA_MARKER.bytes

        hash_bin = Digest::SHA256.digest(combined.pack('C*'))

        raise InvalidPDAError if Solace::Utils::Curve25519Dalek.on_curve?(hash_bin)

        Solace::Utils::Codecs.bytes_to_base58(hash_bin.bytes)
      end

      # Prepares a list of seeds for creating a program address
      #
      # @param seed [String, Integer, Array] The seed to prepare
      # @return [Array] The prepared seeds
      def self.seed_to_bytes(seed)
        case seed
        when String
          looks_like_base58_address?(seed) ? Solace::Utils::Codecs.base58_to_bytes(seed) : seed.bytes
        when Integer
          seed.between?(0, 255) ? [seed] : seed.digits(256)
        when Array
          seed
        else
          seed.to_s.bytes
        end
      end

      # Checks if a string looks like a base58 address
      #
      # @param string [String] The string to check
      # @return [Boolean] True if the string looks like a base58 address, false otherwise
      def self.looks_like_base58_address?(string)
        string.length.between?(32, 44) &&
          Solace::Utils::Codecs.valid_base58?(string)
      end
    end
  end
end

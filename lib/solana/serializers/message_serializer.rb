# frozen_string_literal: true

module Solana
  module Serializers
    # =============================
    # Message Serializer
    # =============================
    #
    # Serializes a Solana message to a binary format.
    class MessageSerializer < Serializers::Base
      include Solana::Utils

      # @!const SERIALIZATION_STEPS
      #   An ordered list of methods to serialize the message
      # 
      # @return [Array] The steps to serialize the message
      SERIALIZATION_STEPS = [
        :encode_version,
        :encode_message_header,
        :encode_accounts,
        :encode_recent_blockhash,
        :encode_instructions,
        :encode_address_lookup_table
      ].freeze

      # Initialize a new serializer
      # 
      # @param message [Solana::Message] The message to serialize
      # @return [Solana::MessageSerializer] The new serializer object
      def initialize(message)
        @msg = message
      end

      # Serializes the message
      # 
      # @return [String] The serialized message (base64)
      def call
        bin = SERIALIZATION_STEPS
          .map { send(_1) }
          .flatten
          .compact
          .pack("C*")

        Base64.strict_encode64(bin)
      end

      private

      attr_reader :msg

      # Encodes the version of the message
      # 
      # The BufferLayout is:
      #   - [Version (1 byte)]
      #
      # @return [Array<Integer>] | nil The bytes of the encoded version
      def encode_version
        [0x80 | msg.version] if msg.versioned?
      end

      # Encodes the message header of the transaction
      # 
      # The BufferLayout is:
      #   - [Message header (3 bytes)]
      #
      # @return [Array<Integer>] The bytes of the encoded message header
      def encode_message_header
        msg.header
      end

      # Encodes the accounts of the transaction
      # 
      # The BufferLayout is:
      #   - [Number of accounts (compact u16)]
      #   - [Accounts (variable length)]
      #
      # @return [Array<Integer>] The bytes of the encoded accounts
      def encode_accounts
        Codecs.encode_compact_u16(msg.accounts.size).bytes + 
        msg.accounts.map { Codecs.base58_to_bytes(_1) }
      end

      # Encodes the recent blockhash of the transaction
      # 
      # The BufferLayout is:
      #   - [Recent blockhash (32 bytes)]
      #
      # @return [Array<Integer>] The bytes of the encoded recent blockhash
      def encode_recent_blockhash
        raise 'Failed to serialize message: recent blockhash is nil' if msg.recent_blockhash.nil?

        Codecs.base58_to_bytes(msg.recent_blockhash)
      end

      # Encodes the instructions of the transaction
      # 
      # The BufferLayout is:
      #   - [Number of instructions (compact u16)]
      #   - [Instructions (variable length)]
      #
      # @return [Array<Integer>] The bytes of the encoded instructions
      def encode_instructions
        Codecs.encode_compact_u16(msg.instructions.size).bytes + 
        msg.instructions.map { _1.to_bytes }
      end

      # Encodes the address lookup table of the transaction
      # 
      # The BufferLayout is:
      #   - [Number of address lookup tables (compact u16)]
      #   - [Address lookup tables (variable length)]
      #
      # @return [Array<Integer>] The bytes of the encoded address lookup table
      def encode_address_lookup_table
        Codecs.encode_compact_u16(msg.address_lookup_tables.size).bytes + 
        msg.address_lookup_tables.map { _1.serialize } if msg.versioned?
      end
    end
  end
end
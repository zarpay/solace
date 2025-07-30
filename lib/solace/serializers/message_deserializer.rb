# frozen_string_literal: true

module Solace
  module Serializers
    # Deserializes a binary message into a Solace::Message object.
    #
    # @since 0.0.1
    class MessageDeserializer < Solace::Serializers::BaseDeserializer
      # @!attribute record_class
      #   The class of the record being deserialized
      #
      # @return [Class] The class of the record
      self.record_class = Solace::Message

      # @!attribute steps
      #   An ordered list of methods to deserialize the message
      #
      # @return [Array] The steps to deserialize the message
      self.steps = %i[
        next_extract_version
        next_extract_message_header
        next_extract_accounts
        next_extract_recent_blockhash
        next_extract_instructions
        next_extract_address_lookup_table
      ]

      # Extract version from the message
      #
      # Checks for version prefix and extracts version. If the prefix is not found, it
      # assumes a legacy message and sets no version.
      #
      # The BufferLayout is:
      #   - [Version prefix (1 byte)]
      #   - [Version (variable length)]
      #
      # @return [Integer] The version of the message
      def next_extract_version
        next_byte = io.read(1).unpack1('C')

        if next_byte & 0x80 == 0x80
          record.version = next_byte & 0x7F
        else
          io.seek(-1, IO::SEEK_CUR)
          record.version = nil
        end
      end

      # Extract message header from the message
      #
      # The BufferLayout is:
      #   - [Message header (3 bytes)]
      #
      # @return [Array<Integer>] The message header of the message
      def next_extract_message_header
        record.header = io.read(3).bytes
      end

      # Extract account keys from the message
      #
      # The BufferLayout is:
      #   - [Number of accounts (compact u16)]
      #   - [Accounts (variable length u8)]
      #
      # @return [Array<String>] The account keys of the message
      def next_extract_accounts
        count, = Codecs.decode_compact_u16(io)
        record.accounts = count.times.map do
          Codecs.bytes_to_base58 io.read(32).bytes
        end
      end

      # Extract recent blockhash from the message
      #
      # The BufferLayout is:
      #   - [Recent blockhash (32 bytes)]
      #
      # @return [String] The recent blockhash of the message
      def next_extract_recent_blockhash
        record.recent_blockhash = Codecs.bytes_to_base58 io.read(32).bytes
      end

      # Extract instructions from the message
      #
      # The BufferLayout is:
      #   - [Number of instructions (compact u16)]
      #   - [Instructions (variable length)]
      #
      # @return [Array<Solace::Instruction>] The instructions of the message
      def next_extract_instructions
        count, = Codecs.decode_compact_u16(io)
        record.instructions = count.times.map do
          Solace::Instruction.deserialize(io)
        end
      end

      # Extract address lookup table from the message
      #
      # The BufferLayout is:
      #   - [Number of address lookup tables (compact u16)]
      #   - [Address lookup tables (variable length)]
      #
      # @return [Array<Solace::AddressLookupTable>] The address lookup table of the message
      def next_extract_address_lookup_table
        return unless record.versioned?

        count, = Codecs.decode_compact_u16(io)
        record.address_lookup_tables = count.times.map do
          Solace::AddressLookupTable.deserialize(io)
        end
      end
    end
  end
end

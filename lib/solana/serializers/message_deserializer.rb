# frozen_string_literal: true

module Solana
  module Serializers 
    # =============================
    # Message Deserializer
    # =============================
    #
    # Deserializes a binary message into a Solana::Message object.
    class MessageDeserializer < Serializers::Base
      include Solana::Utils

      # @!const DESERIALIZATION_STEPS
      #   An ordered list of methods to deserialize the transaction
      # 
      # @return [Array] The steps to deserialize the transaction
      DESERIALIZATION_STEPS = [
        :next_extract_version,
        :next_extract_message_header,
        :next_extract_accounts,
        :next_extract_recent_blockhash,
        :next_extract_instructions,
        :next_extract_address_lookup_table
      ]

      # Initialize a new deserializer
      # 
      # @param io [IO] The bytestream to deserialize
      # @return [Solana::MessageDeserializer] The new deserializer object
      def initialize(io)
        @io = io

        # Initialize message object
        @msg = Solana::Message.new
      end

      # Deserializes a binary message into a Solana::Message object.
      # 
      # @return [Solana::Message] The deserialized message object
      def call
        DESERIALIZATION_STEPS.each { send(_1) }

        raise "End of message not reached. Message data is too long." unless io.eof?

        msg
      end

      private

      attr_reader :io, :msg

      # Extract version from the message
      # 
      # Checks for version prefix and extracts version. If the prefix is not found, it
      # assumes a legacy message and sets no version.
      # 
      # @return [Integer] The version of the message
      def next_extract_version
        next_byte = io.read(1).unpack1("C")

        # Check version prefix
        if next_byte & 0x80 == 0x80
          msg.version = next_byte & 0x7F
        else 
          # Rewind one byte to restore position
          io.seek(-1, IO::SEEK_CUR)
          msg.version = nil
        end
      end

      # Extract message header from the message
      # 
      # @return [Array<Integer>] The message header of the message
      def next_extract_message_header
        msg.header = io.read(3).bytes
      end

      # Extract account keys from the message
      # 
      # @return [Array<String>] The account keys of the message
      def next_extract_accounts
        count, _ = Codecs.decode_compact_u16(io)
        msg.accounts = count.times.map do
          Codecs.bytes_to_base58 io.read(32).bytes 
        end        
      end

      # Extract recent blockhash from the message
      # 
      # @return [String] The recent blockhash of the message
      def next_extract_recent_blockhash
        msg.recent_blockhash = Codecs.bytes_to_base58 io.read(32).bytes
      end

      # Extract instructions from the message
      # 
      # @return [Array<Solana::Instruction>] The instructions of the message
      def next_extract_instructions
        count, _ = Codecs.decode_compact_u16(io)
        msg.instructions = count.times.map do 
          Solana::Instruction.deserialize(io)
        end
      end

      # Extract address lookup table from the message
      # 
      # @return [Array<Solana::AddressLookupTable>] The address lookup table of the message
      def next_extract_address_lookup_table
        return unless msg.versioned?

        count, _ = Codecs.decode_compact_u16(io)
        msg.address_lookup_tables = count.times.map do
          Solana::AddressLookupTable.unpack(io)
        end
      end
    end
  end
end
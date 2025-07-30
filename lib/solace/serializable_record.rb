# frozen_string_literal: true

module Solace
  # !@class SerializableRecord
  #
  # @return [Class]
  class SerializableRecord
    include Solace::Concerns::BinarySerializable

    # Parse record from bytestream
    #
    # @param stream [IO, StringIO] The input to read bytes from.
    # @return [Solace::Instruction] Parsed instruction instance
    def self.deserialize(stream)
      self::DESERIALIZER.call(stream)
    rescue NameError => e
      raise "DESERIALIZER must be defined: #{e.message}"
    end

    # Serializes the record to a binary format
    #
    # @return [String] The serialized record (binary)
    def serialize
      self.class::SERIALIZER.call(self)
    rescue NameError => e
      raise "SERIALIZER must be defined: #{e.message}"
    end
  end
end

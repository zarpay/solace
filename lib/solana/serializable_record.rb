# frozen_string_literal: true

class Solana::SerializableRecord
  include Solana::Concerns::BinarySerializable

  # Parse instruction from io stream
  # 
  # @param io [IO or StringIO] The input to read bytes from.
  # @return [Solana::Instruction] Parsed instruction object
  def self.deserialize(io)
    self::DESERIALIZER.call(io)
  rescue NameError => e
    raise "DESERIALIZER must be defined: #{e.message}"
  end

  # Serializes the transaction to a binary format
  #
  # @return [String] The serialized transaction (binary)
  def serialize
    self.class::SERIALIZER.call(self)
  rescue NameError => e
    raise "SERIALIZER must be defined: #{e.message}"
  end
end

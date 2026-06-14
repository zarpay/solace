---
title: Serialization
---

# Serialization

Solace's wire format — encoding objects to bytes and decoding bytes back — runs through a
small serializer/deserializer framework under `lib/solace/serializers/`. Every core
primitive ([`Transaction`](/concepts/transactions-and-messages),
[`Message`](/concepts/transactions-and-messages#the-message),
[`Instruction`](/concepts/instructions), and
[`AddressLookupTable`](/concepts/address-lookup-tables)) has a matching serializer and
deserializer.

## You usually go through the primitives

You rarely call serializers directly. The primitives expose them:

```ruby
base64 = tx.serialize              # Transaction → base64 (via TransactionSerializer)
tx     = Solace::Transaction.from(base64) # base64 → Transaction (via TransactionDeserializer)
```

`serialize`/`to_binary` and the `.from` constructors are provided by the
`Solace::Concerns::BinarySerializable` mixin, which wires each class to its `SERIALIZER`
and `DESERIALIZER`.

## The framework

Both base classes are step-driven: a subclass declares an ordered list of `steps`
(method names), and the base runs them in sequence.

### `BaseSerializer`

```ruby
class MySerializer < Solace::Serializers::BaseSerializer
  self.steps = %i[encode_header encode_body]

  def encode_header = [...]  # each step returns bytes
  def encode_body   = [...]
end

MySerializer.new(record).call # => base64 String
```

### `BaseDeserializer`

```ruby
class MyDeserializer < Solace::Serializers::BaseDeserializer
  self.steps        = %i[read_header read_body]
  self.record_class = MyRecord

  def read_header = ... # read from self.io (a StringIO), populate self.record
  def read_body   = ...
end

MyDeserializer.new(StringIO.new(binary)).call # => MyRecord
```

Deserializers read from a `StringIO` — get one from RPC base64 with
`Solace::Utils::Codecs.base64_to_bytestream`.

## Bundled serializers

| Primitive | Serializer | Deserializer |
| --- | --- | --- |
| Transaction | `TransactionSerializer` | `TransactionDeserializer` |
| Message | `MessageSerializer` | `MessageDeserializer` |
| Instruction | `InstructionSerializer` | `InstructionDeserializer` |
| Address Lookup Table | `AddressLookupTableSerializer` | `AddressLookupTableDeserializer` |

They handle both legacy and versioned layouts, using the [codecs](/reference/codecs) for the
integer and base58/base64 encodings. The step-driven design is also the extension point: a
new on-chain account type gets serialized by declaring its fields as steps.

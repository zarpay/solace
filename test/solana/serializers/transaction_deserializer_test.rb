# frozen_string_literal: true
require_relative '../../test_helper'

describe Solana::Serializers::TransactionDeserializer do
  describe '#call' do
    describe 'legacy transaction' do
      let(:legacy_tx_io) { Solana::Utils::Codecs.base64_to_bytestream('ATb9iy8YGDhu3n/lblX6vutFwL08V2vO6SWM0tzvXyYKfkl+JHJ+Ne3LQL2ST3bFz+yq8WKY6xRl1gT6Hl7OfwABAAEDFhf39JpMHlteXqQdhkKyBMHDjE/FI1nKB1VAYwoX8usJHpx5omCOgQLd62o8TZKcoP4rwMXr3VxZW7WY5RVdEQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAApnfy5i7sTd9C9sheZ1m39A4THe+MBUS0Mg0CR0ElXsIBAgIAAQwCAAAAQEIPAAAAAAA=') }

      before do
        @tx = Solana::Serializers::TransactionDeserializer.call(legacy_tx_io)
      end

      it 'returns a transaction' do
        assert_kind_of Solana::Transaction, @tx
      end

      it 'extracts signatures' do
        assert_equal 1, @tx.signatures.size
      end

      it 'extracts message' do
        assert_kind_of Solana::Message, @tx.message
      end
    end
    
    describe 'versioned transaction' do
      let(:versioned_tx_io) { Solana::Utils::Codecs.base64_to_bytestream('Acgu9eEm+Vemca/5lLQJbSJYa0YvkB5bGYafvo4thl6lHNYsSAG7sVh4KAX+k2zPl1gf4zd0Yd9Ds+UVOkIhvwWAAQAEDpkYZngZ374Y0pb6toNS8GHchmk84eLPpT4FJYf5crqomSd1qmAcQwzxZ+k/CeilJsmeji0PQ1cYjpPgihQaOIWIBErEGNasI3hrll4pKZsGHXknGG0+wErI4I5gt02GfJYlqLPaiX4sQV4FMW9kLNv5yW7ehfQRK8XbAqgyNWMlNf7CHxePVFUrXDi1BMb/4ybhol6hmYY5qaC5PldZqTEtApC6Uq9mdQdfYV0bL+7LTUAhN/sLOh2FVZeB3rqseUgWJ/Wlr2SJc6B3X4zsauwJo1l30cYqGje+BVlW8rQ+2mxPsy/Mq5zYLYsZPpxwGo2Mf6HYD38wsqhDpTRfMvb5Cbin+fF73r0gMfSNlfSaAnV+fOpSFHPQN5Yq0KXSELfiD4hBX0flO2syRT6ZYt+fhAzZmL93ET+6qG9NydzRAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADBkZv5SEXMv/srbpyw5vnvIzlu8X3EmssQ5s6QAAAAMKC3ZljbddWFnVt++HEh8V+9bue8NoWVHq2eCijyFuLBHnVLe2/a8Xs0J2EU0o0rqWXUEOzb9ArJGULtYRDWVwqyfBc4wPKEDwZ+J83/G1LSd0aTRUzQ+x3nDrAPv64oQQLAAkDAQAAAAAAAAALAAUCY2sOAA05IwAgMS8eLSwdHAggAAggADAKIzIuIiMAEB8OCA8BAQEkIiMAGQIaHxsHBwcrIiMABAIJIAUDBgYMLOUXy5d6460qAAQAAAACFwACEQACEQACEQEfdAAAAAAAAB90AAAAAAAAAAAADRkjAB8mIyclAB8TEiEUESgjKikAIRgXHxYVJOUXy5d6460qAAIAAAACAwIDRzkeAAAAAABHOR4AAAAAAAAAAAZeksiuGUD29Evnx5+b5Awe13wncsSmQU2U1qFnaqfiWANrbJoDbQRpB8dTfmoXCYp/6NAuhjfAkYGFdrwum0jfX4IP+UDTmQwExMbFwwPKyMc9eI6loMOfhEUBficrajwPaSQFTUllI+ZuBSUzy0HtbARQT05NA0lMS9LDB68Y9BoPcKBD37erv38IqCugyHrQuvRdzSVNl2UNA9nd4AHhO9l9gy3odcj1w3FZTmZWYdQ2gP9C6xGhBBeyH+n2swMDW1pXB15YYVZfXGMpc7pKAgpBMfko96SFVmoW5yI6moN3eGQnlJmiZwZQLAOgkUoA') }

      before do
        @tx = Solana::Serializers::TransactionDeserializer.call(versioned_tx_io)
      end

      it 'returns a transaction' do
        assert_kind_of Solana::Transaction, @tx
      end

      it 'extracts signatures' do
        assert_equal 1, @tx.signatures.size
      end

      it 'extracts message' do
        assert_kind_of Solana::Message, @tx.message
      end
    end
  end
end

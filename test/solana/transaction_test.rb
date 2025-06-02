require 'test_helper'

describe Solana::Transaction do
  before do
    # Constants
    @LEGACY_TX = 'AQTOlTZsUqzg6u0IVycmib4bKX7B2T3NcojpY41cl/eEiAASMp3Jw2BRxHjljjzkYIaJ9riCZGaJPs8d1epyqgwBAAQH66k2oxCf1NeH/qx+lTO8hVJaIRFdbOZ9gcllmRxaOY4ePuaeKDiITwFZ8rCSkE+db/L5QJy0xGAauYopfRdP4V8H9slNVtuqE+OCdY1zzix2FyAYSUozZZvscFh9+YmDAwZGb+UhFzL/7K26csOb57yM5bvF9xJrLEObOkAAAAAG3fbh12Whk9nL4UbO63msHLSF7V9bN5E6jPWFfv8AqSKtWWLMxAr/lb3bGSFoFz4J32rEnvAT3IaBkhYHxQ+aO0Qss5EhV/E6kz0BNCgtAytf/s0Botvxt3kGCN8ALqd+cK7yZ+2vzULI/dD7q+Kko7KdVLNIL3Fdfxhts2TjigMDAAUCNCEAAAMACQMgoQcAAAAAAAQGAgYBAAAFCgwQJwAAAAAAAAY='
    @VERSIONED_TX = 'Aaq/sJpfXp/rur6pUDoniGGiqJr9VnsjNjPgB/nF7yct/yvZDkZK83NVm35gngpQXVG8PScoCPZgd0rGrK1b9QSAAQADC5kYZngZ374Y0pb6toNS8GHchmk84eLPpT4FJYf5crqoHSD5PZKUQwLgiCHryaf8nYk/9Al8YGxaabuPi6YsD7E417niAzAcHpomUF/GETKHRYOgv/P1/BLiytOES8dmZqGhggNSUXM2XTqsvfg3BSoR82hoDtF5DPfMmxCnw9kDJjx8nnqzm2jnudUkmtT7OefnKxmLLPwmxna0+Ur5JyNmFYSl4ZtUmvGPp0x4olkD8HeiBYjO1miLKcSNaSmFs2m8wpNK/w2erNxNBqLyr4Ug7KVaSU0C5Mfzx9IdUpl+Z/n96hEZ1/m4PAL+pZejjM0ChyLCm8l9UMVuyGThaW8DBkZv5SEXMv/srbpyw5vnvIzlu8X3EmssQ5s6QAAAAEPgBQCBHk9mdcAVjyWfKoLRkuYzPGFr1h8etE0/GSomBHnVLe2/a8Xs0J2EU0o0rqWXUEOzb9ArJGULtYRDWVx9jg0F4KP4uEEqvdsAUZCEMfqzYLqwiV0Msd0Ri7lW6gQIAAkDAQAAAAAAAAAIAAUCs3QJAAobGwAWHRsAARYEBQYHAwMJHRsADxYRBRACAgIcJuUXy5d6460qAAIAAAACEQECEQCZzggAAAAAAJnOCAAAAAAAAAAAChkbABYfGx4gABYUFRcTEhobGBkAFw4LFgwNJOUXy5d6460qAAIAAAACAwIDcP0/AAAAAABw/T8AAAAAAAAAAARAZBKwJRxRnGTsI+T6zu8hUOLI6lctSWvf4+Ycva/8GQTf4ePkBODi5QKEgS7T31AwSpZVXVVwlUfGebniA/eoCIKFzzwMS83eFAN+WlsCfVmHN+v4qZMpECh9knvF52aQMItF99mqKn4VgxJJ0eR3EQT7+Pr8A/79+SlzukoCCkEx+Sj3pIVWahbnIjqag3d4ZCeUmaJnBlAsAqANAA=='
    
    # IOs
    legacy_io = Solana::Utils::Codecs.base64_to_bytestream(@LEGACY_TX)
    versioned_io = Solana::Utils::Codecs.base64_to_bytestream(@VERSIONED_TX)
    
    # Transactions
    @legacy_tx = Solana::Transaction.deserialize(legacy_io)
    @versioned_tx = Solana::Transaction.deserialize(versioned_io)
  end 

  describe '#serialize' do
    it 'returns serialized legacy transaction' do
      assert_equal @LEGACY_TX, @legacy_tx.serialize
    end

    it 'returns serialized versioned transaction' do
      assert_equal @VERSIONED_TX, @versioned_tx.serialize
    end
  end
end
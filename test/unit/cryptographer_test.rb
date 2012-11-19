require 'test_helper'

module CloudEncryptedSync
  class CryptographerTest < ActiveSupport::TestCase

    test 'should encrypt and decrypt data' do
      precrypted_data = "123xyz"
      encrypted_data = Cryptographer.encrypt_data(precrypted_data)
      decrypted_data = Cryptographer.decrypt_data(encrypted_data)
      assert_equal(precrypted_data,decrypted_data)
    end

    test 'should hash data' do
      hashed_data = Cryptographer.hash_data('abc123')
      assert_equal(128,hashed_data.length)
    end
  end
end
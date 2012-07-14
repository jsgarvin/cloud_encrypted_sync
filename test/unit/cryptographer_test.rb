require 'test_helper'
require 'openssl'

module CloudEncryptedSync
  class CryptographerTest < ActiveSupport::TestCase
    
    test 'should hash data' do
      hash = Cryptographer.hash_data('abc123')
      assert_equal('c70b5dd9ebfb6f51d09d4132b7170c9d20750a7852f00680f65658f0310e810056e6763c34c9a00b0e940076f54495c169fc2302cceb312039271c43469507dc',hash)
    end
    
    test 'should encrypt string' do
      assert_equal('885e57411c7df4fa3b2881410cffd0969cdb700fcce168d2b3addcdec34603ff2ba40e078bb4012a4654bac01f7481049d5aa015aff554935ed8aa967a7728de', Cryptographer.encrypt_string('testing 123'))
    end
    
    test 'should encrypt and decrypt data' do
      unencrypted_data = "123xyz"
      encrypted_data = Cryptographer.encrypt_data(unencrypted_data)
      decrypted_data = Cryptographer.decrypt_data(encrypted_data)
      assert_equal(unencrypted_data,decrypted_data)
    end
    
  end
end
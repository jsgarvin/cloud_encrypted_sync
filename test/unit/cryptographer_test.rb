require 'test_helper'

module CloudEncryptedSync
  class CryptographerTest < ActiveSupport::TestCase

    def setup
      Configuration.stubs(:settings).returns({
        :encryption_key => 'asdf',
        :adapter_name => 'dummy',
        :bucket => "test-bucket",
        :data_dir => "#{Etc.getpwuid.dir}/.cloud_encrypted_sync",
        :sync_path => test_source_folder
      })
    end

    test 'should hash data' do
      hash = Cryptographer.hash_data('abc123')
      assert_equal('c70b5dd9ebfb6f51d09d4132b7170c9d20750a7852f00680f65658f0310e810056e6763c34c9a00b0e940076f54495c169fc2302cceb312039271c43469507dc',hash)
    end

    test 'should encrypt and decrypt data' do
      unencrypted_data = "123xyz"
      encrypted_data = Cryptographer.encrypt_data(unencrypted_data)
      decrypted_data = Cryptographer.decrypt_data(encrypted_data)
      assert_equal(unencrypted_data,decrypted_data)
    end

    test 'test should generate random key' do
      assert_equal(String,Cryptographer.generate_random_key.class)
    end

  end
end
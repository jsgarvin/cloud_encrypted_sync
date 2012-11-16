require 'test_helper'

module CloudEncryptedSync
  class AdapterLiaisonTest < ActiveSupport::TestCase

    test 'should encrypt when writing' do
      precrypted_data = File.read(test_source_folder + '/test_sub_folder/test_file_one.txt')
      key = Cryptographer.hash_data('test_file_key')
      Adapters::Dummy.expects(:write).with(anything,key).returns(true)
      AdapterLiaison.instance.push(precrypted_data,key)
    end

    test 'should decrypt_when_reading' do
      precrypted_data = File.read(test_source_folder + '/test_sub_folder/test_file_one.txt')
      encrypted_data = Cryptographer.encrypt_data(precrypted_data)
      key = Cryptographer.hash_data('test_file_key')
      Adapters::Dummy.expects(:read).with(key).returns(encrypted_data)
      assert_equal(precrypted_data,AdapterLiaison.instance.pull(key))
    end

  end
end
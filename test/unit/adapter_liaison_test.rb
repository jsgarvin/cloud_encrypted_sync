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

    test 'should find adapters' do
      Dir.stubs(:glob).returns([
        '/path/cloud_encrypted_sync_first_test_adapter-1.2.3',
        '/path/cloud_encrypted_sync_second_test_adapter-4.5.6',
        '/path/cloud_encrypted_sync_second_test_adapter-7.8.9'
      ])
      assert_equal({'first_test' => '1.2.3', 'second_test' => '7.8.9'}, AdapterLiaison.instance.send(:latest_versions_of_installed_adapters))
    end

    test 'should require adapters' do
      AdapterLiaison.instance.stubs(:latest_versions_of_installed_adapters).returns({'first_test' => '1.2.3'})
      assert_raises(LoadError) { AdapterLiaison.instance.send(:find_and_require_adapters) }
    end

  end
end
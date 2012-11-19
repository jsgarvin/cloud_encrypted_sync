require 'test_helper'

module CloudEncryptedSync
  class AdapterLiaisonTest < ActiveSupport::TestCase

    test 'should require available adapter' do
      Dir.stubs(:glob).returns(['/path/cloud_encrypted_sync_first_test_adapter-1.2.3'])
      assert_raises(LoadError) { AdapterLiaison.clone.instance }
    end

    test 'should encrypt when writing' do
      precrypted_data = File.read(test_source_folder + '/test_sub_folder/test_file_one.txt')
      Cryptographer.expects(:encrypt_data).with(precrypted_data)
      Adapters::Dummy.expects(:write).with(anything,'test_key')
      AdapterLiaison.instance.push(precrypted_data,'test_key')
    end

    test 'should decrypt_when_reading' do
      precrypted_data = File.read(test_source_folder + '/test_sub_folder/test_file_one.txt')
      encrypted_data = Cryptographer.encrypt_data(precrypted_data)
      Adapters::Dummy.expects(:read).with('test_key').returns(encrypted_data)
      assert_equal(precrypted_data,AdapterLiaison.instance.pull('test_key'))
    end

    test 'should forward delete to dummy' do
      Adapters::Dummy.expects(:delete).with('test_key').returns(true)
      AdapterLiaison.instance.delete('test_key')
    end

    test 'should forward key exists to dummy' do
      Adapters::Dummy.expects(:key_exists?).with('test_key').returns(true)
      AdapterLiaison.instance.key_exists?('test_key')
    end

    test 'should find lastest versions of available adapters' do
      Dir.stubs(:glob).returns([
        '/path/cloud_encrypted_sync_first_test_adapter-1.2.3',
        '/path/cloud_encrypted_sync_second_test_adapter-4.5.6',
        '/path/cloud_encrypted_sync_second_test_adapter-7.8.9'
      ])
      assert_equal({'first_test' => '1.2.3', 'second_test' => '7.8.9'}, AdapterLiaison.instance.send(:latest_versions_of_installed_adapters))
    end

  end
end
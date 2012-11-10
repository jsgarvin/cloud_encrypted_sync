require 'test_helper'
require 'yaml'

module CloudEncryptedSync
  class MasterTest < ActiveSupport::TestCase

    def setup
      Configuration.stubs(:settings).returns({
        :encryption_key => 'asdf',
        :initialization_vector => 'qwerty',
        :adapter_name => 'dummy',
        :bucket => "test-bucket",
        :sync_path => test_source_folder
      })
      Configuration.stubs(:data_folder_path).returns("#{Etc.getpwuid.dir}/.cloud_encrypted_sync")
    end

    test 'should generate directory hash' do
      assert_equal('',$stdout.string)
      hash = Master.send(:directory_hash)
      assert_match(/\% Complete/,$stdout.string)
      assert_equal(1,hash.keys.size)
      assert_equal('test_sub_folder/test_file_one.txt',hash[hash.keys.first])
    end

    test 'should_return_nil_if_never_synced_before' do
      Master.stubs(:snapshot_file_path).returns('/non/existant/file')
      assert_equal(nil,Master.send(:last_sync_date))
    end

    test 'should want to push everything on first run with local files and empty remote' do
      Master.stubs(:remote_directory_hash).returns({})
      Master.stubs(:directory_hash).returns({"old_file_key"=>"test_sub_folder/old_file.txt"})
      Master.stubs(:last_sync_hash).returns({})
      assert_equal(Master.directory_hash,Master.send(:files_to_push))
    end

    test 'should encrypt when writing' do
      precrypted_data = File.read(test_source_folder + '/test_sub_folder/test_file_one.txt')
      encrypted_data = Cryptographer.encrypt_data(precrypted_data)
      key = Cryptographer.hash_data('test_file_key')
      Adapters::Dummy.expects(:write).with(encrypted_data,key).returns(true)
      Master.send(:write_to_adapter,precrypted_data,key)
    end

    test 'should decrypt_when_reading' do
      precrypted_data = File.read(test_source_folder + '/test_sub_folder/test_file_one.txt')
      encrypted_data = Cryptographer.encrypt_data(precrypted_data)
      key = Cryptographer.hash_data('test_file_key')
      Adapters::Dummy.expects(:read).with(key).returns(encrypted_data)
      assert_equal(precrypted_data,Master.send(:read_from_adapter,key))
    end

    test 'should push files' do
      Master.stubs(:remote_directory_hash).returns({})
      Master.stubs(:last_sync_hash).returns({})
      Adapters::Dummy.stubs(:key_exists?).returns(false)
      Adapters::Dummy.expects(:write).with(any_parameters).returns(true)
      assert_equal('',$stdout.string)
      Master.push_files!
      assert_match(/\% Complete/,$stdout.string)
    end

    test 'should want to pull everything on first run with remote files and empty local' do
      Master.stubs(:remote_directory_hash).returns({'new_file_key' => 'test_sub_folder/new_file.txt'})
      Master.stubs(:directory_hash).returns({})
      Master.stubs(:last_sync_hash).returns({})
      assert_equal({'new_file_key' => 'test_sub_folder/new_file.txt'},Master.send(:files_to_pull))
    end

    test 'should pull files' do
      Master.stubs(:remote_directory_hash).returns({'new_file_key' => 'test_sub_folder/new_file.txt'})
      Master.stubs(:directory_hash).returns({})
      Master.stubs(:last_sync_hash).returns({})
      Adapters::Dummy.expects(:read).with('new_file_key').returns(Cryptographer.encrypt_data('foobar'))
      assert_equal('',$stdout.string)
      assert_difference('Dir["#{test_source_folder}/**/*"].length') do
        Master.pull_files!
      end
      assert_match(/\% Complete/,$stdout.string)
    end

    test 'should only want to push new files on later run' do
      Master.stubs(:remote_directory_hash).returns({'old_file_key' => 'test_sub_folder/old_file.txt'})
      Master.stubs(:directory_hash).returns({'new_file_key' => 'test_sub_folder/new_file.txt', 'old_file_key' => 'test_sub_folder/old_file.txt'})
      Master.stubs(:last_sync_hash).returns({'old_file_key' => 'test_sub_folder/old_file.txt'})
      assert_equal({'new_file_key' => 'test_sub_folder/new_file.txt'},Master.send(:files_to_push))
    end

    test 'should want to pull new files from cloud' do
      Master.stubs(:remote_directory_hash).returns({'new_file_key' => 'test_sub_folder/new_file.txt', 'old_file_key' => 'test_sub_folder/old_file.txt'})
      Master.stubs(:directory_hash).returns({'old_file_key' => 'test_sub_folder/old_file.txt'})
      Master.stubs(:last_sync_hash).returns({'old_file_key' => 'test_sub_folder/old_file.txt'})
      assert_equal({'new_file_key' => 'test_sub_folder/new_file.txt'},Master.send(:files_to_pull))
    end

    test 'should want to delete locally missing files from cloud' do
      Master.stubs(:remote_directory_hash).returns({'saved_file_key' => 'test_sub_folder/saved_file.txt', 'deleted_file_key' => 'test_sub_folder/deleted_file.txt'})
      Master.stubs(:directory_hash).returns({'saved_file_key' => 'test_sub_folder/saved_file.txt'})
      Master.stubs(:last_sync_hash).returns({'saved_file_key' => 'test_sub_folder/saved_file.txt', 'deleted_file_key' => 'test_sub_folder/deleted_file.txt'})
      assert_equal({'deleted_file_key' => 'test_sub_folder/deleted_file.txt'},Master.send(:remote_files_to_delete))
    end

    test 'should delete files from cloud' do
      Master.stubs(:remote_directory_hash).returns({'saved_file_key' => 'test_sub_folder/saved_file.txt', 'deleted_file_key' => 'test_sub_folder/deleted_file.txt'})
      Master.stubs(:directory_hash).returns({'saved_file_key' => 'test_sub_folder/saved_file.txt'})
      Master.stubs(:last_sync_hash).returns({'saved_file_key' => 'test_sub_folder/saved_file.txt', 'deleted_file_key' => 'test_sub_folder/deleted_file.txt'})
      Adapters::Dummy.expects(:delete).with('deleted_file_key').returns(true)
      Master.delete_remote_files!
    end

    test 'should want to delete appropriate files locally' do
      Master.stubs(:remote_directory_hash).returns({'saved_file_key' => 'test_sub_folder/saved_file.txt'})
      Master.stubs(:directory_hash).returns({'saved_file_key' => 'test_sub_folder/saved_file.txt', 'deleted_file_key' => 'test_sub_folder/deleted_file.txt'})
      Master.stubs(:last_sync_hash).returns({'saved_file_key' => 'test_sub_folder/saved_file.txt', 'deleted_file_key' => 'test_sub_folder/deleted_file.txt'})
      assert_equal({'deleted_file_key' => 'test_sub_folder/deleted_file.txt'},Master.send(:local_files_to_delete))
    end

    test 'should delete local files' do
      Master.stubs(:remote_directory_hash).returns({'saved_file_key' => 'test_sub_folder/saved_file.txt'})
      Master.stubs(:last_sync_hash).returns({'saved_file_key' => 'test_sub_folder/saved_file.txt', 'deleted_file_key' => 'test_sub_folder/deleted_file.txt'}.merge(Master.send(:directory_hash)))
      assert_difference('Dir["#{test_source_folder}/**/*"].length',-1) do
        Master.delete_local_files!
      end
    end

    test 'should finalize' do
      FileUtils.mkdir_p(Configuration.data_folder_path)
      sample_directory_hash = {'sample_file_key' => 'test_sub_folder/sample_file.txt'}
      double_encrypted_directory_hash = Cryptographer.encrypt_data(Cryptographer.encrypt_data(sample_directory_hash.to_yaml))
      Master.instance_variable_set(:@finalize_required,true)
      Master.stubs(:directory_hash).returns(sample_directory_hash)
      Adapters::Dummy.expects(:write).with(double_encrypted_directory_hash,Master.send(:directory_key)).returns(true)
      Master.finalize!
    end

    test 'should decrypt remote directory file' do
      #setup mock data
      sample_directory_hash = {'sample_file_key' => 'test_sub_folder/sample_file.txt'}
      double_encrypted_directory_hash = Cryptographer.encrypt_data(Cryptographer.encrypt_data(sample_directory_hash.to_yaml))
      Adapters::Dummy.stubs(:read).with(Master.send(:directory_key)).returns(double_encrypted_directory_hash)

      #do actual test
      decrypted_remote_hash = Master.send(:remote_directory_hash)
      assert_equal(sample_directory_hash,decrypted_remote_hash)
    end

  end
end
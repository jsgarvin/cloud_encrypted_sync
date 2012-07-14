require 'test_helper'
require 'yaml'

module CloudEncryptedSync
  class MasterTest < ActiveSupport::TestCase
    
    test 'should generate directory hash' do
      hash = Master.directory_hash
      assert_equal({"19d828911217a736143b0ce84b70cd7e528191005d33f7ca49bd07ba27e20763b4929e790949dad0859cdb7cba67b7daace059bcc7aebef9225eb9e5eaba6264"=>"test_sub_folder/test_file_one.txt"},hash)
    end
    
    test 'should_return_nil_if_never_synced_before' do
      assert_equal(nil,Master.last_sync_date)
    end
    
    test 'should want to push everything on first run with local files and empty remote' do
      Master.stubs(:remote_directory_hash).returns({})
      Master.stubs(:directory_hash).returns({"old_file_key"=>"test_sub_folder/old_file.txt"})
      Master.stubs(:last_sync_hash).returns({})
      assert_equal(Master.directory_hash,Master.files_to_push)
    end
    
    test 'should want to pull everything on first run with remote files and empty local' do
      Master.stubs(:remote_directory_hash).returns({'new_file_key' => 'test_sub_folder/new_file.txt'})
      Master.stubs(:directory_hash).returns({})
      Master.stubs(:last_sync_hash).returns({})
      assert_equal({'new_file_key' => 'test_sub_folder/new_file.txt'},Master.files_to_pull)
    end
    
    test 'should only want to push new files on later run' do
      Master.stubs(:remote_directory_hash).returns({'old_file_key' => 'test_sub_folder/old_file.txt'})
      Master.stubs(:directory_hash).returns({'new_file_key' => 'test_sub_folder/new_file.txt', 'old_file_key' => 'test_sub_folder/old_file.txt'})
      Master.stubs(:last_sync_hash).returns({'old_file_key' => 'test_sub_folder/old_file.txt'})
      assert_equal({'new_file_key' => 'test_sub_folder/new_file.txt'},Master.files_to_push)
    end
    
    test 'should want to pull new files from s3' do
      Master.stubs(:remote_directory_hash).returns({'new_file_key' => 'test_sub_folder/new_file.txt', 'old_file_key' => 'test_sub_folder/old_file.txt'})
      Master.stubs(:directory_hash).returns({'old_file_key' => 'test_sub_folder/old_file.txt'})
      Master.stubs(:last_sync_hash).returns({'old_file_key' => 'test_sub_folder/old_file.txt'})
      assert_equal({'new_file_key' => 'test_sub_folder/new_file.txt'},Master.files_to_pull)
    end
    
    test 'should want to delete locally missing files from s3' do
      Master.stubs(:remote_directory_hash).returns({'saved_file_key' => 'test_sub_folder/saved_file.txt', 'deleted_file_key' => 'test_sub_folder/deleted_file.txt'})
      Master.stubs(:directory_hash).returns({'saved_file_key' => 'test_sub_folder/saved_file.txt'})
      Master.stubs(:last_sync_hash).returns({'saved_file_key' => 'test_sub_folder/saved_file.txt', 'deleted_file_key' => 'test_sub_folder/deleted_file.txt'})
      assert_equal({'deleted_file_key' => 'test_sub_folder/deleted_file.txt'},Master.remote_files_to_delete)
    end
    
    test 'should want to delete appropriate files locally' do
      Master.stubs(:remote_directory_hash).returns({'saved_file_key' => 'test_sub_folder/saved_file.txt'})
      Master.stubs(:directory_hash).returns({'saved_file_key' => 'test_sub_folder/saved_file.txt', 'deleted_file_key' => 'test_sub_folder/deleted_file.txt'})
      Master.stubs(:last_sync_hash).returns({'saved_file_key' => 'test_sub_folder/saved_file.txt', 'deleted_file_key' => 'test_sub_folder/deleted_file.txt'})
      assert_equal({'deleted_file_key' => 'test_sub_folder/deleted_file.txt'},Master.local_files_to_delete)
    end
    
    test 'should send encrypted directory file' do
      sample_directory_hash = {'sample_file_key' => 'test_sub_folder/sample_file.txt'}
      Master.stubs(:directory_hash).returns(sample_directory_hash)
      S3Liason.expects(:write).with(Cryptographer.encrypt_data(sample_directory_hash.to_yaml),Master.directory_key).returns(true)
      Master.store_directory_hash_file
    end
    
    test 'should decrypt remote directory file' do
      #setup mock data
      sample_directory_hash = {'sample_file_key' => 'test_sub_folder/sample_file.txt'}
      S3Liason.stubs(:read).with(Master.directory_key).returns(Cryptographer.encrypt_data(sample_directory_hash.to_yaml))
      
      #do actual test
      decrypted_remote_hash = Master.remote_directory_hash
      assert_equal(sample_directory_hash,decrypted_remote_hash)
    end
    
    test 'should create initial config file' do
      Master.instance_variable_set(:@config, nil)
      
      assert_equal(false,File.exists?(Master::CONFIG_FILE))
      assert_equal(Master::INITIAL_CONFIG,Master.config)
      assert_equal(true,File.exists?(Master::CONFIG_FILE))
    end
  end
end
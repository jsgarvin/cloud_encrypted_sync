require 'test_helper'
require File.expand_path('../../../lib/cryptiferous', __FILE__)


class CryptiferousTest < ActiveSupport::TestCase
  
  test 'should generate directory hash' do
    hash = Cryptiferous.directory_hash
    assert_equal({"7904ae460e85873e0fd6a9de9ef143d4191cdbf96055f64e93b12b111e691653"=>"test_sub_folder/test_file_one.txt"},hash)
  end
  
  test 'should write readable yml file' do
    begin
      test_yaml_path = File.expand_path('../../test_folder/test.yaml',  __FILE__)
      assert_equal(false,File.exist?(test_yaml_path))
      
      hash = Cryptiferous.directory_hash
      
      file = File.open(test_yaml_path,'w+')
      file.write(hash.to_yaml)
      file.close
      
      assert_equal(true,File.exist?(test_yaml_path))
      
      new_hash = YAML.load_file(test_yaml_path)
      assert_equal(hash,new_hash)
    ensure
      File.delete(test_yaml_path) if File.exist?(test_yaml_path)
    end
  end
  
  test 'should_return_nil_if_never_synced_before' do
    assert_equal(nil,Cryptiferous.last_sync_date)
  end
  
  test 'should want to push everything on first run with local files and empty remote' do
    Cryptiferous.stubs(:remote_directory_hash).returns({})
    assert_equal(Cryptiferous.directory_hash,Cryptiferous.files_to_push)
  end
  
  test 'should want to pull everything on first run with remote files and empty local' do
    Cryptiferous.stubs(:remote_directory_hash).returns({'new_file_key' => 'test_sub_folder/new_file.txt'})
    Cryptiferous.stubs(:directory_hash).returns({})
    Cryptiferous.stubs(:last_sync_hash).returns({})
    assert_equal({'new_file_key' => 'test_sub_folder/new_file.txt'},Cryptiferous.files_to_pull)
  end
  
  test 'should only want to push new files on later run' do
    Cryptiferous.stubs(:remote_directory_hash).returns({'old_file_key' => 'test_sub_folder/old_file.txt'})
    Cryptiferous.stubs(:directory_hash).returns({'new_file_key' => 'test_sub_folder/new_file.txt', 'old_file_key' => 'test_sub_folder/old_file.txt'})
    Cryptiferous.stubs(:last_sync_hash).returns({'old_file_key' => 'test_sub_folder/old_file.txt'})
    assert_equal({'new_file_key' => 'test_sub_folder/new_file.txt'},Cryptiferous.files_to_push)
  end
  
  test 'should want to pull new files from s3' do
    Cryptiferous.stubs(:remote_directory_hash).returns({'new_file_key' => 'test_sub_folder/new_file.txt', 'old_file_key' => 'test_sub_folder/old_file.txt'})
    Cryptiferous.stubs(:directory_hash).returns({'old_file_key' => 'test_sub_folder/old_file.txt'})
    Cryptiferous.stubs(:last_sync_hash).returns({'old_file_key' => 'test_sub_folder/old_file.txt'})
    assert_equal({'new_file_key' => 'test_sub_folder/new_file.txt'},Cryptiferous.files_to_pull)
  end
  
  test 'should want to delete locally missing files from s3' do
    Cryptiferous.stubs(:remote_directory_hash).returns({'saved_file_key' => 'test_sub_folder/saved_file.txt', 'deleted_file_key' => 'test_sub_folder/deleted_file.txt'})
    Cryptiferous.stubs(:directory_hash).returns({'saved_file_key' => 'test_sub_folder/saved_file.txt'})
    Cryptiferous.stubs(:last_sync_hash).returns({'saved_file_key' => 'test_sub_folder/saved_file.txt', 'deleted_file_key' => 'test_sub_folder/deleted_file.txt'})
    assert_equal({'deleted_file_key' => 'test_sub_folder/deleted_file.txt'},Cryptiferous.remote_files_to_delete)
  end
  
  test 'should want to delete appropriate files locally' do
    Cryptiferous.stubs(:remote_directory_hash).returns({'saved_file_key' => 'test_sub_folder/saved_file.txt'})
    Cryptiferous.stubs(:directory_hash).returns({'saved_file_key' => 'test_sub_folder/saved_file.txt', 'deleted_file_key' => 'test_sub_folder/deleted_file.txt'})
    Cryptiferous.stubs(:last_sync_hash).returns({'saved_file_key' => 'test_sub_folder/saved_file.txt', 'deleted_file_key' => 'test_sub_folder/deleted_file.txt'})
    assert_equal({'deleted_file_key' => 'test_sub_folder/deleted_file.txt'},Cryptiferous.local_files_to_delete)
  end
  
  test 'should write encrypted directory file to s3' do
    encrypted_file_path = "#{File.expand_path('../../../temp',  __FILE__)}/folder_snapshot.yml.encrypted"
    S3Liason.stubs(:write).with(encrypted_file_path,Cryptiferous.directory_key).returns(true)
    Cryptiferous.store_directory_hash_file
  end
  
  test 'should read encrypted directory file from s3' do
    encrypted_data = File.open(Cryptiferous.generate_directory_file).read
    S3Liason.stubs(:read).with(Cryptiferous.directory_key).returns(encrypted_data)
    Cryptiferous.remote_directory_hash
  end
  
end
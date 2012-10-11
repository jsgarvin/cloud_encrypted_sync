require 'test_helper'
require 'yaml'

module CloudEncryptedSync
  class MasterTest < ActiveSupport::TestCase

    test 'should generate directory hash' do
      assert_equal('',$stdout.string)
      hash = Master.send(:directory_hash)
      assert_match(/\% Complete/,$stdout.string)
      assert_equal(1,hash.keys.size)
      assert_equal('test_sub_folder/test_file_one.txt',hash[hash.keys.first])
    end

    test 'should_return_nil_if_never_synced_before' do
      assert_equal(nil,Master.send(:last_sync_date))
    end

    test 'should want to push everything on first run with local files and empty remote' do
      Master.stubs(:remote_directory_hash).returns({})
      Master.stubs(:directory_hash).returns({"old_file_key"=>"test_sub_folder/old_file.txt"})
      Master.stubs(:last_sync_hash).returns({})
      assert_equal(Master.directory_hash,Master.send(:files_to_push))
    end

    test 'should push files' do
      Master.stubs(:remote_directory_hash).returns({})
      Master.stubs(:last_sync_hash).returns({})
      S3Liason.stubs(:key_exists?).returns(false)
      S3Liason.expects(:write).with(any_parameters).returns(true)
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
      S3Liason.expects(:read).with('new_file_key').returns(Cryptographer.encrypt_data('foobar'))
      assert_equal('',$stdout.string)
      assert_difference('Dir["#{Master.send(:sync_path)}/**/*"].length') do
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

    test 'should want to pull new files from s3' do
      Master.stubs(:remote_directory_hash).returns({'new_file_key' => 'test_sub_folder/new_file.txt', 'old_file_key' => 'test_sub_folder/old_file.txt'})
      Master.stubs(:directory_hash).returns({'old_file_key' => 'test_sub_folder/old_file.txt'})
      Master.stubs(:last_sync_hash).returns({'old_file_key' => 'test_sub_folder/old_file.txt'})
      assert_equal({'new_file_key' => 'test_sub_folder/new_file.txt'},Master.send(:files_to_pull))
    end

    test 'should want to delete locally missing files from s3' do
      Master.stubs(:remote_directory_hash).returns({'saved_file_key' => 'test_sub_folder/saved_file.txt', 'deleted_file_key' => 'test_sub_folder/deleted_file.txt'})
      Master.stubs(:directory_hash).returns({'saved_file_key' => 'test_sub_folder/saved_file.txt'})
      Master.stubs(:last_sync_hash).returns({'saved_file_key' => 'test_sub_folder/saved_file.txt', 'deleted_file_key' => 'test_sub_folder/deleted_file.txt'})
      assert_equal({'deleted_file_key' => 'test_sub_folder/deleted_file.txt'},Master.send(:remote_files_to_delete))
    end

    test 'should delete files from s3' do
      Master.stubs(:remote_directory_hash).returns({'saved_file_key' => 'test_sub_folder/saved_file.txt', 'deleted_file_key' => 'test_sub_folder/deleted_file.txt'})
      Master.stubs(:directory_hash).returns({'saved_file_key' => 'test_sub_folder/saved_file.txt'})
      Master.stubs(:last_sync_hash).returns({'saved_file_key' => 'test_sub_folder/saved_file.txt', 'deleted_file_key' => 'test_sub_folder/deleted_file.txt'})
      S3Liason.expects(:delete).with('deleted_file_key').returns(true)
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
      assert_difference('Dir["#{Master.send(:sync_path)}/**/*"].length',-1) do
        Master.delete_local_files!
      end
    end

    test 'should finalize' do
      FileUtils.mkdir_p(Master.send(:data_folder_path))
      sample_directory_hash = {'sample_file_key' => 'test_sub_folder/sample_file.txt'}
      Master.instance_variable_set(:@finalize_required,true)
      Master.stubs(:directory_hash).returns(sample_directory_hash)
      S3Liason.expects(:write).with(Cryptographer.encrypt_data(sample_directory_hash.to_yaml),Master.send(:directory_key)).returns(true)
      Master.finalize!
    end

    test 'should decrypt remote directory file' do
      #setup mock data
      sample_directory_hash = {'sample_file_key' => 'test_sub_folder/sample_file.txt'}
      S3Liason.stubs(:read).with(Master.send(:directory_key)).returns(Cryptographer.encrypt_data(sample_directory_hash.to_yaml))

      #do actual test
      decrypted_remote_hash = Master.send(:remote_directory_hash)
      assert_equal(sample_directory_hash,decrypted_remote_hash)
    end

    test 'should parse command line options' do
      Master.instance_variable_set(:@command_line_options,nil)
      Object.send(:remove_const,:ARGV)
      ::ARGV = '--s3-bucket foobar --data-dir ~/test/folder --encryption-key somestringofcharacters --initialization-vector asdfg --s3-credentials access_key_id,access_key'.split(/\s/)
      Master.parse_command_line_options
      clo = Master.instance_variable_get(:@command_line_options)
      assert_equal('foobar',clo[:s3_bucket])
      assert_equal('~/test/folder',clo[:data_dir])
      assert_equal('somestringofcharacters',clo[:encryption_key])
      assert_equal('asdfg',clo[:initialization_vector])
      assert_equal(['access_key_id','access_key'],clo[:s3_credentials])
    end

    test 'should gracefully fail on path in ARGV' do
      Master.instance_variable_set(:@command_line_options,nil)
      Object.send(:remove_const,:ARGV)
      ::ARGV = '--s3-bucket foobar'.split(/\s/)
      assert_equal('',$stdout.string)
      Master.expects(:pull_files).never
      Master.sync! { Master.pull_files! }
      assert_match(/You must supply a path/,$stdout.string)
    end

    test 'should gracefully fail when not provided encryption_key and vector provided path in ARGV' do
      Master.instance_variable_set(:@config,{})
      Master.instance_variable_set(:@command_line_options,nil)
      Object.send(:remove_const,:ARGV)
      ::ARGV = '--s3-bucket foobar /some/path/to/sync'.split(/\s/)
      assert_equal('',$stdout.string)
      Master.expects(:pull_files!).never
      Master.sync! { Master.pull_files! }
      assert_match(/You must supply an encryption key and initialization vector/,$stdout.string)
    end

    test 'should successfully call block with minimum cli arguments' do
      File.stubs(:exist?).with(Master.send(:config_file_path)).returns(false)
      Master.instance_variable_set(:@command_line_options,nil)
      Object.send(:remove_const,:ARGV)
      ::ARGV = '--s3-bucket foobar --encryption-key mykey --initialization-vector vector /some/path/to/sync'.split(/\s/)
      Master.expects(:pull_files!).returns(true).once
      Master.sync! { Master.pull_files! }
    end
  end
end
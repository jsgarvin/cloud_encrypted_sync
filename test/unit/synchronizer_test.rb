require 'test_helper'

module CloudEncryptedSync
  class SynchronizerTest < ActiveSupport::TestCase

    test 'should_return_nil_if_never_synced_before' do
      Synchronizer.stubs(:snapshot_file_path).returns('/non/existant/file')
      assert_equal(nil,Synchronizer.send(:last_sync_date))
    end

    test 'should want to push everything on first run with local files and empty remote' do
      Index.stubs(:remote).returns({})
      Index.stubs(:local).returns({"old_file_key"=>"test_sub_folder/old_file.txt"})
      Synchronizer.stubs(:last_sync_hash).returns({})
      assert_equal(Index.local,Synchronizer.send(:files_to_push))
    end

    test 'should push files' do
      Synchronizer.stubs(:remote_directory_hash).returns({})
      Synchronizer.stubs(:last_sync_hash).returns({})
      Adapters::Dummy.stubs(:key_exists?).returns(false)
      Adapters::Dummy.expects(:write).with(any_parameters).returns(true)
      assert_equal('',$stdout.string)
      Synchronizer.push_files!
      assert_match(/\% Complete/,$stdout.string)
    end

    test 'should want to pull everything on first run with remote files and empty local' do
      Index.stubs(:remote).returns({'new_file_key' => 'test_sub_folder/new_file.txt'})
      Index.stubs(:local).returns({})
      Synchronizer.stubs(:last_sync_hash).returns({})
      assert_equal({'new_file_key' => 'test_sub_folder/new_file.txt'},Synchronizer.send(:files_to_pull))
    end

    test 'should pull files' do
      Index.stubs(:remote).returns({'new_file_key' => 'test_sub_folder/new_file.txt'})
      Index.stubs(:local).returns({})
      Synchronizer.stubs(:last_sync_hash).returns({})
      Adapters::Dummy.expects(:read).with('new_file_key').returns(Cryptographer.encrypt_data('foobar'))
      assert_equal('',$stdout.string)
      assert_difference('Dir["#{test_source_folder}/**/*"].length') do
        Synchronizer.pull_files!
      end
      assert_match(/\% Complete/,$stdout.string)
    end

    test 'should only want to push new files on later run' do
      Index.stubs(:remote).returns({'old_file_key' => 'test_sub_folder/old_file.txt'})
      Index.stubs(:local).returns({'new_file_key' => 'test_sub_folder/new_file.txt', 'old_file_key' => 'test_sub_folder/old_file.txt'})
      Synchronizer.stubs(:last_sync_hash).returns({'old_file_key' => 'test_sub_folder/old_file.txt'})
      assert_equal({'new_file_key' => 'test_sub_folder/new_file.txt'},Synchronizer.send(:files_to_push))
    end

    test 'should want to pull new files from cloud' do
      Index.stubs(:remote).returns({'new_file_key' => 'test_sub_folder/new_file.txt', 'old_file_key' => 'test_sub_folder/old_file.txt'})
      Index.stubs(:local).returns({'old_file_key' => 'test_sub_folder/old_file.txt'})
      Synchronizer.stubs(:last_sync_hash).returns({'old_file_key' => 'test_sub_folder/old_file.txt'})
      assert_equal({'new_file_key' => 'test_sub_folder/new_file.txt'},Synchronizer.send(:files_to_pull))
    end

    test 'should want to delete locally missing files from cloud' do
      Index.stubs(:remote).returns({'saved_file_key' => 'test_sub_folder/saved_file.txt', 'deleted_file_key' => 'test_sub_folder/deleted_file.txt'})
      Index.stubs(:local).returns({'saved_file_key' => 'test_sub_folder/saved_file.txt'})
      Synchronizer.stubs(:last_sync_hash).returns({'saved_file_key' => 'test_sub_folder/saved_file.txt', 'deleted_file_key' => 'test_sub_folder/deleted_file.txt'})
      assert_equal({'deleted_file_key' => 'test_sub_folder/deleted_file.txt'},Synchronizer.send(:remote_files_to_delete))
    end

    test 'should delete files from cloud' do
      Index.stubs(:remote).returns({'saved_file_key' => 'test_sub_folder/saved_file.txt', 'deleted_file_key' => 'test_sub_folder/deleted_file.txt'})
      Index.stubs(:local).returns({'saved_file_key' => 'test_sub_folder/saved_file.txt'})
      Synchronizer.stubs(:last_sync_hash).returns({'saved_file_key' => 'test_sub_folder/saved_file.txt', 'deleted_file_key' => 'test_sub_folder/deleted_file.txt'})
      Adapters::Dummy.expects(:delete).with('deleted_file_key').returns(true)
      Synchronizer.delete_remote_files!
    end

    test 'should want to delete appropriate files locally' do
      Index.stubs(:remote).returns({'saved_file_key' => 'test_sub_folder/saved_file.txt'})
      Index.stubs(:local).returns({'saved_file_key' => 'test_sub_folder/saved_file.txt', 'deleted_file_key' => 'test_sub_folder/deleted_file.txt'})
      Synchronizer.stubs(:last_sync_hash).returns({'saved_file_key' => 'test_sub_folder/saved_file.txt', 'deleted_file_key' => 'test_sub_folder/deleted_file.txt'})
      assert_equal({'deleted_file_key' => 'test_sub_folder/deleted_file.txt'},Synchronizer.send(:local_files_to_delete))
    end

    test 'should delete local files' do
      Index.stubs(:remote).returns({'saved_file_key' => 'test_sub_folder/saved_file.txt'})
      Synchronizer.stubs(:last_sync_hash).returns({'saved_file_key' => 'test_sub_folder/saved_file.txt', 'deleted_file_key' => 'test_sub_folder/deleted_file.txt'}.merge(Index.local))
      assert_difference('Dir["#{test_source_folder}/**/*"].length',-1) do
        Synchronizer.delete_local_files!
      end
    end

    test 'should finalize' do
      FileUtils.mkdir_p(Configuration.data_folder_path)
      sample_directory_hash = {'sample_file_key' => 'test_sub_folder/sample_file.txt'}
      Synchronizer.instance_variable_set(:@finalize_required,true)
      Synchronizer.stubs(:directory_hash).returns(sample_directory_hash)
      Adapters::Dummy.expects(:write).with(anything,Index.send(:index_key)).returns(true)
      Synchronizer.finalize!
    end

    test 'should decrypt remote directory file' do
      #setup mock data
      sample_directory_hash = {'sample_file_key' => 'test_sub_folder/sample_file.txt'}
      encrypted_directory_hash = Cryptographer.encrypt_data(sample_directory_hash.to_yaml)
      Adapters::Dummy.expects(:read).with(Index.send(:index_key)).returns(encrypted_directory_hash)

      #do actual test
      decrypted_remote_hash = Index.remote
      assert_equal(sample_directory_hash,decrypted_remote_hash)
    end

    test 'should puts error message to stdout' do
      Configuration.stubs(:settings).raises(Errors::IncompleteConfigurationError,'test message')
      assert_equal('',$stdout.string)
      Synchronizer.expects(:pull_files).never
      Synchronizer.run
      assert_match(/test message/,$stdout.string)
    end

  end
end
require 'test_helper'

module CloudEncryptedSync
  class SynchronizerTest < ActiveSupport::TestCase

    SYNC_METHODS = [:delete_local_files, :delete_remote_files, :push_files, :pull_files, :finalize]

    test 'should run full sync' do
      SYNC_METHODS.each { |method_name| Synchronizer.expects(method_name) }

      Synchronizer.run
    end

    test 'should puts error message to stdout when config is incomplete' do
      Configuration.stubs(:settings).raises(Errors::IncompleteConfigurationError,'test message')
      AdapterLiaison.expects(:push).never
      AdapterLiaison.expects(:pull).never

      assert_equal('',$stdout.string)
      Synchronizer.run
      assert_match(/test message/,$stdout.string)
    end

    test 'should push files' do
      Adapters::Dummy.expects(:write)

      assert_equal('',$stdout.string)
      Synchronizer.push_files
      assert_match(/\% Complete/,$stdout.string)
    end

    test 'should not push files that already exist' do
      AdapterLiaison.instance.stubs(:key_exists?).returns(true)
      Synchronizer.push_files
      assert_match(/\(already exists\)/,$stdout.string)
    end

    test 'should pull files' do
      Index.stubs(:remote).returns({'new_file_key' => 'test_sub_folder/new_file.txt'})
      Adapters::Dummy.expects(:read).with('new_file_key').returns(Cryptographer.encrypt_data('foobar'))
      assert_equal('',$stdout.string)
      assert_difference('Dir["#{test_source_folder}/**/*"].length') do
        Synchronizer.pull_files
      end
      assert_match(/\% Complete/,$stdout.string)
    end

    test 'should not pull files that already exist' do
      Synchronizer.stubs(:files_to_pull).returns({:foo => 'bar'})
      File.stubs(:exist?).returns(true)
      Index.stubs(:file_key).returns(:foo)
      Synchronizer.pull_files
      assert_match(/\(already exists\)/,$stdout.string)
    end

    test 'should gracefully recover if pull fails' do
      Synchronizer.stubs(:files_to_pull).returns({:foo => 'bar'})
      AdapterLiaison.instance.stubs(:pull).raises(Errors::NoSuchKey)
      Synchronizer.pull_files
      assert_match(/Failed to pull/,$stdout.string)
    end

    test 'should delete files from cloud' do
      Index.stubs(:remote).returns({'saved_file_key' => 'test_sub_folder/saved_file.txt', 'deleted_file_key' => 'test_sub_folder/deleted_file.txt'})
      Index.stubs(:local).returns({'saved_file_key' => 'test_sub_folder/saved_file.txt'})
      Synchronizer.stubs(:last_sync_hash).returns({'saved_file_key' => 'test_sub_folder/saved_file.txt', 'deleted_file_key' => 'test_sub_folder/deleted_file.txt'})
      Adapters::Dummy.expects(:delete).with('deleted_file_key').returns(true)
      Synchronizer.delete_remote_files
      assert_match(/Deleting Remote/,$stdout.string)
    end

    test 'should delete local files' do
      Index.stubs(:remote).returns({'saved_file_key' => 'test_sub_folder/saved_file.txt'})
      Synchronizer.stubs(:last_sync_hash).returns({'saved_file_key' => 'test_sub_folder/saved_file.txt'}.merge(Index.local))
      assert_difference('Dir["#{test_source_folder}/**/*"].length',-1) do
        Synchronizer.delete_local_files
      end
      assert_match(/Deleting Local/,$stdout.string)
    end

    test 'should gracefully recover if local file disappears before delete' do
      Synchronizer.stubs(:local_files_to_delete).returns({:foo => 'bar'})
      File.stubs(:exist?).returns(false)
      Synchronizer.delete_local_files
      assert_match(/Not Deleting Local/,$stdout.string)
    end

    test 'should finalize' do
      Synchronizer.instance_variable_set(:@finalize_required,true)
      Index.expects(:write)

      Synchronizer.finalize
    end

    test 'should want to push everything on first run with local files and empty remote' do
      Index.stubs(:remote).returns({})
      Index.stubs(:local).returns({"new_file_key"=>"test_sub_folder/new_file.txt"})
      Synchronizer.stubs(:last_sync_hash).returns({})
      assert_equal(Index.local,Synchronizer.send(:files_to_push))
    end

    test 'should want to push new files with available last sync hash' do
      new_file_hash = {"new_file_key"=>"test_sub_folder/new_file.txt"}
      Index.stubs(:remote).returns({"old_file_key"=>"test_sub_folder/old_file.txt"})
      Index.stubs(:local).returns({"old_file_key"=>"test_sub_folder/old_file.txt"}.merge(new_file_hash))
      Synchronizer.stubs(:last_sync_hash).returns({"old_file_key"=>"test_sub_folder/old_file.txt"})
      assert_equal(new_file_hash,Synchronizer.send(:files_to_push))
    end

    test 'should want to push new files with local and remote files and empty last sync hash' do
      new_file_hash = {"new_file_key"=>"test_sub_folder/new_file.txt"}
      Index.stubs(:remote).returns({"old_file_key"=>"test_sub_folder/old_file.txt"})
      Index.stubs(:local).returns({"old_file_key"=>"test_sub_folder/old_file.txt"}.merge(new_file_hash))
      Synchronizer.stubs(:last_sync_hash).returns({})
      assert_equal(new_file_hash,Synchronizer.send(:files_to_push))
    end

    test 'should want to puull everything on first run with no local files and remote files available' do
      Index.stubs(:remote).returns({"new_file_key"=>"test_sub_folder/new_file.txt"})
      Index.stubs(:local).returns({})
      Synchronizer.stubs(:last_sync_hash).returns({})
      assert_equal(Index.remote,Synchronizer.send(:files_to_pull))
    end

    test 'should want to pull new files with available last sync hash' do
      new_file_hash = {"new_file_key"=>"test_sub_folder/new_file.txt"}
      Index.stubs(:remote).returns({"old_file_key"=>"test_sub_folder/old_file.txt"}.merge(new_file_hash))
      Index.stubs(:local).returns({"old_file_key"=>"test_sub_folder/old_file.txt"})
      Synchronizer.stubs(:last_sync_hash).returns({"old_file_key"=>"test_sub_folder/old_file.txt"})
      assert_equal(new_file_hash,Synchronizer.send(:files_to_pull))
    end

    test 'should want to pull new files with local and remote files and empty last sync hash' do
      new_file_hash = {"new_file_key"=>"test_sub_folder/new_file.txt"}
      Index.stubs(:remote).returns({"old_file_key"=>"test_sub_folder/old_file.txt"}.merge(new_file_hash))
      Index.stubs(:local).returns({"old_file_key"=>"test_sub_folder/old_file.txt"})
      Synchronizer.stubs(:last_sync_hash).returns({})
      assert_equal(new_file_hash,Synchronizer.send(:files_to_pull))
    end

    test 'should not want to delete remote files if last sync hash is empty' do
      Index.stubs(:remote).returns({"old_file_key"=>"test_sub_folder/old_file.txt"})
      Index.stubs(:local).returns({})
      Synchronizer.stubs(:last_sync_hash).returns({})
      assert_equal({},Synchronizer.send(:remote_files_to_delete))
    end

    test 'should want to delete remote files' do
      Index.stubs(:remote).returns({"old_file_key"=>"test_sub_folder/old_file.txt"})
      Index.stubs(:local).returns({})
      Synchronizer.stubs(:last_sync_hash).returns({"old_file_key"=>"test_sub_folder/old_file.txt"})
      assert_equal(Index.remote,Synchronizer.send(:remote_files_to_delete))
    end

    test 'should not want to delete local files if last sync hash is empty' do
      Index.stubs(:remote).returns({})
      Index.stubs(:local).returns({"old_file_key"=>"test_sub_folder/old_file.txt"})
      Synchronizer.stubs(:last_sync_hash).returns({})
      assert_equal({},Synchronizer.send(:local_files_to_delete))
    end

    test 'should want to delete local files' do
      Index.stubs(:remote).returns({})
      Index.stubs(:local).returns({"old_file_key"=>"test_sub_folder/old_file.txt"})
      Synchronizer.stubs(:last_sync_hash).returns({"old_file_key"=>"test_sub_folder/old_file.txt"})
      assert_equal(Index.local,Synchronizer.send(:local_files_to_delete))
    end
  end
end
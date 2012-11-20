require 'test_helper'

module CloudEncryptedSync
  class IndexTest < ActiveSupport::TestCase

    test 'should compile local directory hash' do
      assert_equal('',$stdout.string)
      hash = Index.local
      assert_equal(1,hash.keys.size)
      assert_equal('test_sub_folder/test_file_one.txt',hash[hash.keys.first])
      assert_match(/\% Complete/,$stdout.string)
    end

    test 'should fetch remote directory hash' do
      AdapterLiaison.instance.expects(:pull).returns({:some => 'hash'}.to_yaml)
      assert_equal({:some => 'hash'},Index.remote)
    end

    test 'should return empty hash if no remote index' do
      Index.instance_variable_set(:@remote,nil)
      AdapterLiaison.instance.expects(:pull).raises(Errors::NoSuchKey)
      assert_equal({},Index.remote)
    end

    test 'should recompile and write local and remote hashes' do
      Configuration.send(:touch_data_folder)
      AdapterLiaison.instance.expects(:push)
      FakeFS::File.any_instance.expects(:read).returns('Testing 123')
      Index.write
    end

    test 'should return full normalized file path' do
      assert_match(/.+\/test\/test_folder\/foobar$/,Index.full_file_path('foobar'))
    end

    test 'should leave sync path unchanged' do
      Configuration.stubs(:settings).returns({:sync_path => '/foo/bar/'})
      assert_equal('/foo/bar/',Index.send(:normalize_sync_path))
    end

    test 'should add trailing slash to sync path' do
      Configuration.stubs(:settings).returns({:sync_path => '/foo/bar'})
      assert_equal('/foo/bar/',Index.send(:normalize_sync_path))
    end

  end
end
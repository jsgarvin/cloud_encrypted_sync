require 'test_helper'

module CloudEncryptedSync
  class IndexTest < ActiveSupport::TestCase

    test 'should generate directory hash' do
      Index.instance_variable_set(:@local, nil)
      assert_equal('',$stdout.string)
      hash = Index.local
      assert_equal(1,hash.keys.size)
      assert_equal('test_sub_folder/test_file_one.txt',hash[hash.keys.first])
      assert_match(/\% Complete/,$stdout.string)
    end

    test 'should add / to end of sync_path' do
      Configuration.stubs(:settings).returns(:sync_path => '/some/path/without/a/trailing/slash')
      assert_equal('/some/path/without/a/trailing/slash/',Index.send(:normalize_sync_path))
    end

    test 'should not add / to end of sync_path' do
      Configuration.stubs(:settings).returns(:sync_path => '/some/path/with/a/trailing/slash/')
      assert_equal('/some/path/with/a/trailing/slash/',Index.send(:normalize_sync_path))
    end

    test 'should return directory hash of index' do
      Index.instance_variable_set(:@remote,nil)
      AdapterLiaison.instance.expects(:pull).returns({:some => 'hash'}.to_yaml)
      assert_equal({:some => 'hash'},Index.remote)
    end

    test 'should return empty hash if no remote index' do
      Index.instance_variable_set(:@remote,nil)
      AdapterLiaison.instance.expects(:pull).raises(Errors::NoSuchKey)
      assert_equal({},Index.remote)
    end
  end
end
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

  end
end
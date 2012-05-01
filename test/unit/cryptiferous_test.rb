require File.expand_path('../../../lib/cryptiferous', __FILE__)
require 'test/unit'

class CryptiferousTest < Test::Unit::TestCase
  
  def test_should_generate_directory_hash
    hash = Cryptiferous.directory_hash(File.expand_path('../../test_folder',  __FILE__))
    assert_equal({"8be114e248f87e8c1e7bc6c7b7b3b9f073a93c1b"=>"test_sub_folder/test_file_one.txt"},hash)
  end
  
  def test_should_hash_file
    hash = Cryptiferous.hash_file(File.expand_path('../../test_folder/test_sub_folder/test_file_one.txt',  __FILE__))
    assert_equal(OpenSSL::Digest::SHA1,hash.class)
  end
end
require File.expand_path('../../../lib/s3', __FILE__)
require 'test/unit'

class S3Test < Test::Unit::TestCase
  
  def setup
    S3.bucket_name = 'jsgarvin-cryptiferous-test'
    S3.bucket.clear!
  end
  
  def test_should_return_open_connection_to_s3
    assert_equal(AWS::S3,S3.connection.class)
  end
  
  def test_should_write_readable_encrypted_yaml_file_to_s3
    assert_equal(0,S3.bucket.objects.count)
    S3.write(File.expand_path('../../test_folder/test_sub_folder/test_file_one.txt',  __FILE__))
    assert_equal(1,S3.bucket.objects.count)
  end
  
  def test_should_write_and_read_encrypted_directory_file_to_s3
    path = File.expand_path('../../test_folder',  __FILE__)
    assert_equal(0,S3.bucket.objects.count)
    S3.store_directory_hash_file(path)
    assert_equal(1,S3.bucket.objects.count)
    well_traveled_directory_hash = S3.fetch_directory_hash
    assert_equal(Cryptiferous.directory_hash(path),well_traveled_directory_hash)
  end
  
end
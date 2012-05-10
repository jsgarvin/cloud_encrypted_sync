require File.expand_path('../../../lib/s3_liason', __FILE__)
require 'test_helper'

class S3LiasonTest < ActiveSupport::TestCase
  
  def test_should_return_open_connection_to_s3
    assert_equal(AWS::S3,S3Liason.connection.class)
  end
  
  def test_should_write_readable_encrypted_yaml_file_to_s3
    assert_equal(0,S3Liason.bucket.objects.count)
    S3Liason.write(File.expand_path('../../test_folder/test_sub_folder/test_file_one.txt',  __FILE__))
    assert_equal(1,S3Liason.bucket.objects.count)
  end
  
end
require 'test_helper'
require File.expand_path('../../../lib/s3_liason', __FILE__)

class S3LiasonTest < ActiveSupport::TestCase
  
  setup :remove_s3_liason_roadblock
  
  test 'should write readable encrypted yaml file to s3' do
    assert_equal(0,S3Liason.send(:bucket).objects.count)
    S3Liason.write(File.expand_path('../../test_folder/test_sub_folder/test_file_one.txt',  __FILE__))
    assert_equal(1,S3Liason.send(:bucket).objects.count)
  end
  
  #######
  private
  #######
  
  def remove_s3_liason_roadblock
    S3Liason.unstub(:read)
    S3Liason.unstub(:write)
  end
  
end
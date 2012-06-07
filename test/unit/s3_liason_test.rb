require 'test_helper'
#require File.expand_path('../../../lib/s3_liason', __FILE__)

class S3LiasonTest < ActiveSupport::TestCase
  
  setup :remove_s3_liason_roadblock
  
  test 'should write readable encrypted yaml file to s3' do
    skip 'message' if true
    test_file_path = File.expand_path('../../test_folder/test_sub_folder/test_file_one.txt',  __FILE__)
    hash_key = Cryptographer.hash_file(test_file_path)
    assert_equal(0,S3Liason.send(:bucket).objects.count)
    assert !S3Liason.send(:bucket).objects[Cryptographer.hash_file(test_file_path)].exists?
    
    S3Liason.write(test_file_path)
    
    assert_equal(1,S3Liason.send(:bucket).objects.count)
    assert S3Liason.send(:bucket).objects[hash_key].exists?
    
    assert_equal(File.open(test_file_path,'rb').read,File.open(S3Liason.read(hash_key),'rb').read)
  end
  
  #######
  private
  #######
  
  def remove_s3_liason_roadblock
    S3Liason.unstub(:read)
    S3Liason.unstub(:write)
  end
  
end
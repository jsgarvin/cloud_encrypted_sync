require 'active_support'
require 'active_support/test_case'
require 'test/unit'

class ActiveSupport::TestCase

  setup :set_config
  
  def set_config
    S3.instance_variable_set(:@bucket_name, 'jsgarvin-cryptiferous-test')
    S3.bucket.clear!
    Cryptiferous.instance_variable_set(:@base_path, File.expand_path('../test_folder',  __FILE__) + '/') 
  end
  
end
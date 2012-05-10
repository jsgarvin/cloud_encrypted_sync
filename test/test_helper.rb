require 'active_support'
require 'active_support/test_case'
require 'test/unit'

class ActiveSupport::TestCase

  setup :set_config
  
  def set_config
    S3Liason.instance_variable_set(:@bucket_name, 'jsgarvin-cryptiferous-test')
    S3Liason.bucket.clear!
    File.delete(Cryptiferous.send(:directory_file_path)) if File.exist?(Cryptiferous.send(:directory_file_path))
    Cryptiferous.instance_variable_set(:@base_path, File.expand_path('../test_folder',  __FILE__) + '/')
    Cryptiferous.instance_variable_set(:@last_sync_hash, nil)
    Cryptiferous.instance_variable_set(:@last_sync_date, nil)
  end
  
end
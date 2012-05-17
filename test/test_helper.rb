require 'rubygems'
require 'bundler/setup'
Bundler.require(:default, :test)
require 'test/unit'

SimpleCov.start

require 'master'

class ActiveSupport::TestCase

  setup :activate_fake_fs
  setup :set_config
  setup :roadblock_s3_liason
  teardown :deactivate_fake_fs
  
  def set_config
    @temp_folder_path = File.expand_path('../../temp', __FILE__)
    S3Liason.instance_variable_set(:@bucket_name, 'jsgarvin-cryptiferous-test')
    S3Liason.send(:bucket).clear!
    Master.instance_variable_set(:@base_path, File.expand_path('../test_folder',  __FILE__) + '/')
    Master.instance_variable_set(:@last_sync_hash, nil)
    Master.instance_variable_set(:@last_sync_date, nil)
    Master.stubs(:data_directory).returns(File.expand_path('../data', __FILE__))
  end
  
  def activate_fake_fs
    FakeFS.activate!
  end
  
  def deactivate_fake_fs
    FakeFS.deactivate!
  end
  
  def roadblock_s3_liason
    S3Liason.stubs(:write).raises(RuntimeError, "You're supposed to stub out S3Liason methods, jerky boy.")
    S3Liason.stubs(:read).raises(RuntimeError, "You're supposed to stub out S3Liason methods, jerky boy.")
  end
  
end
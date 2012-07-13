require 'rubygems'
require 'bundler/setup'
require 'simplecov'
require 'fakefs/safe'
require 'active_support/test_case'
require 'test/unit'

SimpleCov.start

require 'master'

class ActiveSupport::TestCase

  setup :activate_fake_fs
  setup :set_config
  setup :roadblock_s3_liason
  teardown :deactivate_fake_fs
  
  def set_config
    Master.instance_variable_set(:@config, {'encryption_key' => 'asdf', 'initialization_vector' => 'qwerty', 's3_credentials' => {}, 's3_bucket_name' => ''})
    source_dir = File.expand_path('../test_folder',  __FILE__)
    Master.instance_variable_set(:@base_path, source_dir + '/')
    FileUtils.mkdir_p source_dir
    FileUtils.mkdir_p source_dir + '/test_sub_folder'
    File.open(source_dir + '/test_sub_folder/test_file_one.txt', 'w') do |test_file|
      test_file.write('Test File One')
    end
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

require 'mocha'
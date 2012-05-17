require 'simplecov'
SimpleCov.start
require 'active_support'
require 'active_support/test_case'
require 'test/unit'
require 'mocha'


class ActiveSupport::TestCase

  setup :set_config
  setup :roadblock_s3_liason
  teardown :cleanup_files
  
  def set_config
    @temp_folder_path = File.expand_path('../../temp', __FILE__)
    S3Liason.instance_variable_set(:@bucket_name, 'jsgarvin-cryptiferous-test')
    S3Liason.send(:bucket).clear!
    Master.instance_variable_set(:@base_path, File.expand_path('../test_folder',  __FILE__) + '/')
    Master.instance_variable_set(:@last_sync_hash, nil)
    Master.instance_variable_set(:@last_sync_date, nil)
    Master.stubs(:data_directory).returns(File.expand_path('../data', __FILE__))
  end
  
  def cleanup_files
    File.delete(Cryptiferous.send(:directory_file_path)) if File.exist?(Master.send(:directory_file_path))
    if File.exist?(@temp_folder_path + '/../test/data/folder_snapshot.yml')
      File.delete(@temp_folder_path + '/../test/data/folder_snapshot.yml')
    end
    if File.exist?(@temp_folder_path + '/directory_structure.yml.encrypted')
      File.delete(@temp_folder_path + '/directory_structure.yml.encrypted')
    end
    if File.exist?(@temp_folder_path + '/directory_structure.yml.encrypted.decrypted')
      File.delete(@temp_folder_path + '/directory_structure.yml.encrypted.decrypted')
    end
    if File.exist?(@temp_folder_path + '/stubbed_remote_directory_hash.yml')
      File.delete(@temp_folder_path + '/stubbed_remote_directory_hash.yml')
    end
    if File.exist?(@temp_folder_path + '/stubbed_remote_directory_hash.yml.encrypted')
      File.delete(@temp_folder_path + '/stubbed_remote_directory_hash.yml.encrypted')
    end
  end
  
  def roadblock_s3_liason
    S3Liason.stubs(:write).raises(RuntimeError, "You're supposed to stub out S3Liason methods, jerky boy.")
    S3Liason.stubs(:read).raises(RuntimeError, "You're supposed to stub out S3Liason methods, jerky boy.")
  end
  
end
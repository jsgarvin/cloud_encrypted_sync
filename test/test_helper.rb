require 'rubygems'
require 'bundler/setup'
require 'simplecov'
require 'fakefs/safe'
require 'active_support/test_case'
require 'test/unit'
require 'etc'

SimpleCov.start

require 'cloud_encrypted_sync'

module CloudEncryptedSync
  class ActiveSupport::TestCase

    setup :activate_fake_fs
    setup :setup_environment
    setup :roadblock_s3_liason
    setup :capture_stdout
    teardown :deactivate_fake_fs
    teardown :release_stdout

    def setup_environment
      Master.instance_variable_set(:@command_line_options, {
        :encryption_key => 'asdf',
        :initialization_vector => 'qwerty',
        :s3_bucket => "ces-test-bucket-#{Etc.hash}",
        :data_dir => "#{Etc.getpwuid.dir}/.cloud_encrypted_sync"
      })
      source_dir = File.expand_path('../test_folder',  __FILE__)
      Master.instance_variable_set(:@sync_path, source_dir + '/')
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

    def capture_stdout
      @stdout_original = $stdout
      $stdout = StringIO.new
    end

    def release_stdout
      $stdout = @stdout_original
    end
  end
end
require 'mocha'
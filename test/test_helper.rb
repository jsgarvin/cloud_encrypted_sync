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

    S3_LIASON_STUBBABLE_METHODS = [:red,:write,:delete,:key_exists?]

    setup :activate_fake_fs
    setup :preset_environment
    setup :roadblock_s3_liason
    setup :capture_stdout
    teardown :deactivate_fake_fs
    teardown :release_stdout

    def preset_environment
      Master.instance_variable_set(:@config,nil)
      Master.instance_variable_set(:@command_line_options, {
        :encryption_key => 'asdf',
        :initialization_vector => 'qwerty',
        :s3_bucket => "ces-test-bucket-#{Etc.hash}",
        :data_dir => "#{Etc.getpwuid.dir}/.cloud_encrypted_sync"
      })
      source_dir = File.expand_path('../test_folder',  __FILE__)
      Master.instance_variable_set(:@sync_path, source_dir + '/')
      Master.instance_variable_set(:@directory_hash, nil)
      FileUtils.mkdir_p source_dir
      FileUtils.mkdir_p source_dir + '/test_sub_folder'
      File.open(source_dir + '/test_sub_folder/test_file_one.txt', 'w') do |test_file|
        test_file.write('Test File One')
      end
    end

    def activate_fake_fs
      FakeFS.activate!
      FakeFS::FileSystem.clear
    end

    def deactivate_fake_fs
      FakeFS.deactivate!
    end

    def roadblock_s3_liason
      S3_LIASON_STUBBABLE_METHODS.each do |method_name|
        S3Liason.stubs(method_name).raises(RuntimeError, "You're supposed to stub out S3Liason.#{method_name}(), jerky boy.")
      end
    end

    #Capture STDOUT from program for testing and not cluttering test output
    def capture_stdout
      @stdout = $stdout
      $stdout = StringIO.new
    end

    def release_stdout
      $stdout = @stdout
    end

    #Redirect intentional puts from within test to the real STDOUT for troublshooting purposes.
    def puts(*args)
      @stdout.puts(*args)
    end

  end
end
require 'mocha'
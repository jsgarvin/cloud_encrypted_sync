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
    setup :preset_environment
    setup :capture_stdout
    teardown :deactivate_fake_fs
    teardown :release_stdout

    def preset_environment
      Configuration.instance_variable_set(:@settings,nil)
      Configuration.instance_variable_set(:@command_line_options,nil)
      Master.instance_variable_set(:@directory_hash, nil)
      FileUtils.mkdir_p test_source_folder
      FileUtils.mkdir_p test_source_folder + '/test_sub_folder'
      File.open(test_source_folder + '/test_sub_folder/test_file_one.txt', 'w') do |test_file|
        test_file.write('Test File One')
      end
    end

    def test_source_folder
      @test_source_folder ||= File.expand_path('../test_folder',  __FILE__)
    end

    def activate_fake_fs
      FakeFS.activate!
      FakeFS::FileSystem.clear
    end

    def deactivate_fake_fs
      FakeFS.deactivate!
    end

    #Capture STDOUT from program for testing and not cluttering test output
    def capture_stdout
      @stdout = $stdout
      $stdout = StringIO.new
    end

    def release_stdout
      $stdout = @stdout
    end

    #Redirect intentional puts from within tests to the real STDOUT for troublshooting purposes.
    def puts(*args)
      @stdout.puts(*args)
    end

  end
end
require 'mocha'
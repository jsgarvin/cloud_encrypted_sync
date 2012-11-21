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

    setup :initialize_environment
    setup :capture_stdout
    teardown :deactivate_fake_fs
    teardown :release_stdout

    def initialize_environment
      initialize_fake_fs
      stub_configuration
      Index.instance_variable_set(:@local,nil)
      Index.instance_variable_set(:@remote,nil)
    end

    def stub_configuration
      Configuration.stubs(:settings).returns({
        :encryption_key => 'asdf',
        :adapter_name => 'dummy',
        :bucket => "test-bucket",
        :sync_path => test_source_folder
      })
      Configuration.stubs(:data_folder_path).returns("#{Etc.getpwuid.dir}/.cloud_encrypted_sync")
      Adapters::Dummy.any_instance.stubs(:bucket_name).returns('test-bucket')
    end

    def unstub_configuration
      Configuration.unstub(:settings)
      Configuration.unstub(:data_folder_path)
      Adapters::Dummy.any_instance.unstub(:bucket_name)
    end

    def test_source_folder
      @test_source_folder ||= File.expand_path('../test_folder',  __FILE__)
    end

    def initialize_fake_fs
      FakeFS.activate!
      FakeFS::FileSystem.clear
      FileUtils.mkdir_p test_source_folder
      FileUtils.mkdir_p test_source_folder + '/test_sub_folder'
      File.open(test_source_folder + '/test_sub_folder/test_file_one.txt', 'w') do |test_file|
        test_file.write('Test File One')
      end
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
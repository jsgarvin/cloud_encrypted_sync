require 'test_helper'

module CloudEncryptedSync
  class ConfigurationTest < ActiveSupport::TestCase

    def setup
      unstub_configuration
      reset_configuration
    end

    test 'should load settings' do
      ::ARGV = '--adapter dummy --bucket foobar --data-dir ~/test/folder --encryption-key somestringofcharacters /some/path'.split(/\s/)
      settings = Configuration.settings
      assert_equal('dummy',settings[:adapter_name])
      assert_equal('~/test/folder',settings[:data_dir])
      assert_equal('somestringofcharacters',settings[:encryption_key])
      assert_equal('foobar',Adapters::Dummy.instance.bucket_name)
    end

    test 'should gracefully fail without path in ARGV' do
      ::ARGV = '--adapter dummy --bucket foobar'.split(/\s/)
      assert_raise(Errors::IncompleteConfigurationError) { Configuration.settings }
    end

    test 'should gracefully fail when not provided encryption_key and provided path in ARGV' do
      ::ARGV = '--adapter dummy --bucket foobar /some/path/to/sync'.split(/\s/)
      assert_raise(Errors::IncompleteConfigurationError) { Configuration.settings }
    end

    test 'should gracefully fail with invalid adapter provided' do
      ::ARGV = '--adapter nonexistent --bucket foobar'.split(/\s/)
      assert_raise(Errors::IncompleteConfigurationError) { Configuration.settings }
    end

    test 'should create data folder if it does not exist' do
      ::ARGV = '--adapter dummy --bucket foobar --data-dir /test --encryption-key somestringofcharacters /some/path'.split(/\s/)
      assert ! File.exist?('/test')
      Configuration.settings
      assert File.exist?('/test')
    end

    test 'different arguments should produce different signature' do
      # setup first signature
      ::ARGV = '--adapter dummy --bucket foobar --data-dir /test --encryption-key somestringofcharacters /some/path'.split(/\s/)
      Configuration.settings
      first_signature = Configuration.signature

      reset_configuration

      # setup second signature with different bucket
      ::ARGV = '--adapter dummy --bucket foobar2 --data-dir /test --encryption-key somestringofcharacters /some/path'.split(/\s/)
      Configuration.settings
      second_signature = Configuration.signature

      refute_equal(first_signature,second_signature)
    end

    #######
    private
    #######

    def reset_configuration
      Configuration.instance_variable_set(:@cached_argv,nil)
      Configuration.instance_variable_set(:@command_line_options,nil)
      Configuration.instance_variable_set(:@config_file_settings,nil)
      Configuration.instance_variable_set(:@settings,nil)
      Configuration.instance_variable_set(:@option_parser,nil)
      Object.send(:remove_const,:ARGV)
    end
  end
end
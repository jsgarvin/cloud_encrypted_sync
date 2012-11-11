require 'test_helper'

module CloudEncryptedSync
  class ConfigurationTest < ActiveSupport::TestCase

    def setup
      Configuration.instance_variable_set(:@command_line_options,nil)
      Configuration.instance_variable_set(:@settings,nil)
      Configuration.instance_variable_set(:@option_parser,nil)
      Object.send(:remove_const,:ARGV) #if defined?(::ARGV)
    end

    test 'should parse command line options' do
      ::ARGV = '--adapter dummy --bucket foobar --data-dir ~/test/folder --encryption-key somestringofcharacters /some/path'.split(/\s/)
      settings = Configuration.settings
      assert_equal('dummy',settings[:adapter_name])
      assert_equal('~/test/folder',settings[:data_dir])
      assert_equal('somestringofcharacters',settings[:encryption_key])
      assert_equal('foobar',settings[:bucket_name])
    end

    test 'should gracefully fail without path in ARGV' do
      ::ARGV = '--adapter dummy --bucket foobar'.split(/\s/)
      assert_raise(IncompleteConfigurationError) { Configuration.settings }
    end

    test 'should gracefully fail when not provided encryption_key and vector provided path in ARGV' do
      ::ARGV = '--adapter dummy --bucket foobar /some/path/to/sync'.split(/\s/)
      assert_raise(IncompleteConfigurationError) { Configuration.settings }
    end

  end
end
require 'test_helper'

module CloudEncryptedSync
  class AdapterTemplateTest < ActiveSupport::TestCase

    test 'should raise errors on public methods' do

      method_argument_map = {
        :parse_command_line_options => [:foo,:bar],
        :write => [:foo,:bar],
        :read => :foobar,
        :delete => :foobar,
        :key_exists? => :foobar
      }
      method_argument_map.each_pair do |method,arguments|
        assert_raise(Errors::TemplateMethodCalled) { Adapters::Template.send(method,*arguments) }
      end
    end

  end
end
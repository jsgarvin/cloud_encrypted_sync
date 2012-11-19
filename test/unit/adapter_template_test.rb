require 'test_helper'

module CloudEncryptedSync
  class AdapterTemplateTest < ActiveSupport::TestCase

    test 'should register with parent class on inheritance' do
      Adapters::Template.expects(:register_subclass_with_parent).returns(true)
      Class.new(Adapters::Template)
    end

    test 'should contain registered adapters' do
      assert_equal([:dummy],Adapters::Template.children.keys)
    end

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
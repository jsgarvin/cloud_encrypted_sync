module CloudEncryptedSync
  module Adapters
    class Template

      class << self

        def inherited(subclass)
          AdapterLiaison.instance.register(subclass)
        end

        def parse_command_line_options(opts,command_line_options)
          raise Errors::TemplateMethodCalled.new('parse_command_line_options')
        end

        def write(data, key)
          raise Errors::TemplateMethodCalled.new('write')
        end

        def read(key)
          raise Errors::TemplateMethodCalled.new('read')
        end

        def delete(key)
          raise Errors::TemplateMethodCalled.new('delete')
        end

        def key_exists?(key)
          raise Errors::TemplateMethodCalled.new('key_exists?')
        end

      end
    end
  end
end
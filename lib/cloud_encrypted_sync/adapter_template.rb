module CloudEncryptedSync
  module Adapters
    class Template

      class << self

        def inherited(subclass)
          register_subclass_with_parent(subclass)
        end

        def children
          @children ||= {}
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

        #######
        private
        #######

        def register_subclass_with_parent(subclass)
          name = formated_name_of(subclass)
          children[name] ||= subclass
        end

        def formated_name_of(subclass)
          subclass.name.match(/([^:]+)$/)[0].underscore.to_sym
        end
      end
    end
  end
end
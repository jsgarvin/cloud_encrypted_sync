module CloudEncryptedSync
  module Adapters
    class Template

      class << self

        def inherited(subclass)
          AdapterLiaison.instance.register(subclass)
        end

        def parse_command_line_options(opts,command_line_options)
          raise 'called template method: parse_command_line_options'
        end

        def write(data, key)
          raise 'called template method: write'
        end

        def read(key)
          raise 'called template method: read'
        end

        def delete(key)
          raise 'called template method: delete'
        end

        def key_exists?(key)
          raise 'called template method: key_exists?'
        end

      end
    end
  end
end
module CloudEncryptedSync
  module Adapters
    class Dummy < Template

      class << self

        def write(data,key)
          stored_data[key] = data
        end

        def parse_command_line_options(opts,command_line_options)
          opts.on('--bucket BUCKETNAME', 'Name of cloud adapter to use.') do |bucket_name|
            command_line_options[:bucket_name] = bucket_name
          end
          return command_line_options
        end

        def read(key)
          raise "key doesn't exist" unless key_exists?(key)
          stored_data[bucket_name][key]
        end

        def delete(key)
          stored_data[bucket_name].delete(key)
        end

        def key_exists?(key)
          stored_data[bucket_name][key] ? true : false
        end

        #######
        private
        #######

        def stored_data
          @stored_data ||= { bucket_name => {} }
        end

        def bucket_name
          raise RuntimeError, Configuration.settings.inspect
          Configuration.settings[:bucket_name].to_sym
        end

      end
    end
  end
end
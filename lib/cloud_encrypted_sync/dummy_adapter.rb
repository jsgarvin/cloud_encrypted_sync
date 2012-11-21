module CloudEncryptedSync
  module Adapters
    class Dummy < Template
      attr_accessor :bucket_name

      def write(data,key)
        stored_data[bucket_name][key] = data
      end

      def parse_command_line_options(parser)
        parser.on('--bucket BUCKETNAME', 'Name of cloud adapter to use.') do |bucket_argument|
          self.bucket_name = bucket_argument
        end
      end

      def read(key)
        raise Errors::NoSuchKey.new("key doesn't exist: #{key}") unless key_exists?(key)
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

    end
  end
end
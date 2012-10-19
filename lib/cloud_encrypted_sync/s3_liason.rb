require 'aws-sdk'

module CloudEncryptedSync
  class S3Liason

    class << self

      def write(data, key)
        bucket.objects.create(key,data)
      end

      def read(key)
        bucket.objects[key].read
      end

      def delete(key)
        bucket.objects[key].delete
      end

      def key_exists?(key)
        bucket.objects[key].exists?
      end

      #######
      private
      #######

      def credentials
        Master.config[:s3_credentials]
      end

      def connection
        @connection ||= AWS::S3.new(:access_key_id => credentials[0], :secret_access_key => credentials[1])
      end

      def bucket_name
        @bucket_name ||= Master.config[:s3_bucket]
      end

      def bucket
        connection.buckets[bucket_name]
      end

    end
  end
end
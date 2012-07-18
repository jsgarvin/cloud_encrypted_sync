require 'aws-sdk'

module CloudEncryptedSync
  class S3Liason
    
    class << self
      
      def write(data, key = nil)
        hash_key = key || Cryptographer.hash_data(data)
        encrypted_data = Cryptographer.encrypt_data(data)
        bucket.objects.create(hash_key,encrypted_data)
      end
      
      def read(key)
        Cryptographer.decrypt_data(bucket.objects[key].read)
      end
      
      def delete(key)
        bucket.objects[key].delete
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
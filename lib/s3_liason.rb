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
      
      #######
      private
      #######
      
      def connection
        @connection ||= AWS::S3.new(Master.config['s3_credentials'])
      end
      
      def bucket_name
        @bucket_name ||= Master.config['s3_bucket_name']
      end
      
      def bucket
        connection.buckets[bucket_name]
      end
      
    end
  end
end
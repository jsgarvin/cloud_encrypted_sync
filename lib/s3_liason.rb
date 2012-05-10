require 'aws-sdk'
class S3Liason
  
  class << self
    
    
    
    def write(path, key = nil)
      hash_key = key || Cryptiferous.hash_file(path)
      bucket.objects.create(hash_key,File.open(path))
    end
    
    def read(key)
      bucket.objects[key].read
    end
    
    #######
    private
    #######
    
    def connection
      @connection ||= AWS::S3.new(Cryptiferous::CONFIG['s3_credentials'])
    end
    
    def bucket_name
      @bucket_name ||= Cryptiferous::CONFIG['s3_bucket_name']
    end
    
    def bucket
      connection.buckets[@bucket_name]
    end
    
  end
end
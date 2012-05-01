require 'aws-sdk'
class S3
  
  class << self
    
    def connection
      @connection ||= AWS::S3.new(Cryptiferous::CONFIG['s3_credentials'])
    end
    
    def bucket_name
      @bucket_name ||= Cryptiferous::CONFIG['bucket_name']
    end
    
    def bucket_name=(string)
      @bucket_name = string
    end
    
    def bucket
      connection.buckets[@bucket_name]
    end
    
    def write(path)
      hash_key = Cryptiferous.hash_file(path)
      bucket.objects.create(hash_key,File.open(path))
    end
    
  end
end
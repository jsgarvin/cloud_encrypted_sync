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
    
    def write(path, key = nil)
      hash_key = key || Cryptiferous.hash_file(path)
      bucket.objects.create(hash_key,File.open(path))
    end
    
    def store_directory_hash_file(root_path)
      path = Cryptiferous.generate_directory_file(root_path)
      encrypted_file_path = Cryptiferous.encrypt_file(path)
      File.delete(path)
      S3.write(encrypted_file_path,Cryptiferous.directory_key)
      File.delete(encrypted_file_path)
    end
    
    def fetch_directory_hash
      return Cryptiferous.decrypt_directory_file(bucket.objects[Cryptiferous.directory_key].read)
    end
  end
end
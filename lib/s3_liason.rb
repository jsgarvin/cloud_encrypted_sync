require 'aws-sdk'
class S3Liason
  
  class << self
    
    def write(path, key = nil)
      hash_key = key || Cryptographer.hash_file(path)
      encrypted_file_path = Cryptographer.encrypt_file(path)
      begin
        bucket.objects.create(hash_key,File.open(encrypted_file_path,'rb'))
      ensure
        File.delete(encrypted_file_path)
      end
    end
    
    def read(key)
      temp_path = File.expand_path("../../temp/#{key}",  __FILE__)
      File.open(temp_path,'wb') do |file|
        file.write bucket.objects[key].read
      end
      Cryptographer.decrypt_file(temp_path)
    end
    
    #######
    private
    #######
    
    def connection
      @connection ||= AWS::S3.new(Master::CONFIG['s3_credentials'])
    end
    
    def bucket_name
      @bucket_name ||= Master::CONFIG['s3_bucket_name']
    end
    
    def bucket
      connection.buckets[bucket_name]
    end
    
  end
end
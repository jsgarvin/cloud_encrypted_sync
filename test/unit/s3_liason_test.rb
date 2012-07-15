require 'test_helper'

module CloudEncryptedSync
  class S3LiasonTest < ActiveSupport::TestCase
    
    setup :remove_s3_liason_roadblock
    setup :load_s3_credentials
    setup :create_test_bucket
    
    teardown :delete_test_bucket
    
    test 'should write readable encrypted file to s3' do

      skip 'S3 credentials for test bucket not provided.' unless Master.config[:s3_credentials].is_a?(Array) and Master.config[:s3_credentials] != []

      test_file_path = File.expand_path('../../test_folder/test_sub_folder/test_file_one.txt',  __FILE__)
      hash_key = Cryptographer.hash_data(File.open(test_file_path).read)
      assert_equal(0,S3Liason.send(:bucket).objects.count)
      assert !S3Liason.send(:bucket).objects[hash_key].exists?
      
      S3Liason.write(File.open(test_file_path).read)
      
      assert_equal(1,S3Liason.send(:bucket).objects.count)
      assert S3Liason.send(:bucket).objects[hash_key].exists?
      
      assert_equal(File.open(test_file_path,'rb').read,S3Liason.read(hash_key))
    end
    
    #######
    private
    #######
    
    def remove_s3_liason_roadblock
      S3Liason.unstub(:read)
      S3Liason.unstub(:write)
    end
    
    def load_s3_credentials
      FakeFS.deactivate!
      real_config = YAML.load_file(Master.send(:config_file_path)) if File.exist?(Master.send(:config_file_path))
      FakeFS.activate!
      
      if real_config && real_config['s3_credentials']
        Master.instance_variable_set(:@config, Master.config.merge({ :s3_credentials => real_config['s3_credentials'] }))
      end
    end
    
    def create_test_bucket
      Master.instance_variable_set(:@config, Master.config.merge({ :s3_bucket => "cloud_encrypted_sync_unit_test_bucket_#{Digest::SHA1.hexdigest(rand.to_s)}" }))
      S3Liason.send(:connection).buckets.create(Master.config[:s3_bucket])
    end
    
    def delete_test_bucket
      S3Liason.send(:bucket).delete! unless Master.config[:s3_credentials] == [] or !Master.config[:s3_credentials].is_a?(Array)
    end
  end
end
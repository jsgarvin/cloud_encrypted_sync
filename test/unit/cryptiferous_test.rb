require File.expand_path('../../../lib/cryptiferous', __FILE__)
require 'test/unit'
require 'yaml'
require 'openssl'

class CryptiferousTest < Test::Unit::TestCase
  
  def test_should_generate_directory_hash
    hash = Cryptiferous.directory_hash(File.expand_path('../../test_folder',  __FILE__))
    assert_equal({"7904ae460e85873e0fd6a9de9ef143d4191cdbf96055f64e93b12b111e691653"=>"test_sub_folder/test_file_one.txt"},hash)
    
  end
  
  def test_should_hash_file
    hash = Cryptiferous.hash_file(File.expand_path('../../test_folder/test_sub_folder/test_file_one.txt',  __FILE__))
    assert_equal(Digest::SHA2,hash.class)
  end
  
  def test_should_write_readable_yml_file
    begin
      test_yaml_path = File.expand_path('../../test_folder/test.yaml',  __FILE__)
      assert_equal(false,File.exist?(test_yaml_path))
      
      hash = Cryptiferous.directory_hash(File.expand_path('../../test_folder',  __FILE__))
      
      file = File.open(test_yaml_path,'w+')
      file.write(hash.to_yaml)
      file.close
      
      assert_equal(true,File.exist?(test_yaml_path))
      
      new_hash = YAML.load_file(test_yaml_path)
      assert_equal(hash,new_hash)
    ensure
      File.delete(test_yaml_path)
    end
  end
  
  def test_should_write_encrypted_version_of_file
    begin
      key = S3::CONFIG['encryption_key']
      alg = "AES-128-CBC"
      iv = "6543210987654321"
      
      aes = OpenSSL::Cipher::Cipher.new(alg)
      aes.encrypt
      aes.key = key
      aes.iv = iv
  
      File.open(File.expand_path('../../test_folder/test_sub_folder/test_file_one.txt.enc',  __FILE__),'w') do |encrypted_file|
        File.open(File.expand_path('../../test_folder/test_sub_folder/test_file_one.txt',  __FILE__)) do |unencrypted_file|
          loop do
            data = unencrypted_file.read(4096)
            break unless data
            cipher = aes.update(data)
            encrypted_file << cipher
          end
          encrypted_file << aes.final
        end
      end
      
      aes = OpenSSL::Cipher::Cipher.new(alg)
      aes.decrypt
      aes.key = key
      aes.iv = iv
      
      File.open(File.expand_path('../../test_folder/test_sub_folder/test_file_one.txt.dec',  __FILE__),'w') do |decrypted_file|
        File.open(File.expand_path('../../test_folder/test_sub_folder/test_file_one.txt.enc',  __FILE__)) do |encrypted_file|
          loop do
            data = encrypted_file.read(4096)
            break unless data
            cipher = aes.update(data)
            decrypted_file << cipher
          end
          decrypted_file << aes.final
        end
      end
      
      assert_equal(
        File.open(File.expand_path('../../test_folder/test_sub_folder/test_file_one.txt',  __FILE__)).read,
        File.open(File.expand_path('../../test_folder/test_sub_folder/test_file_one.txt.dec',  __FILE__)).read
      )
    ensure
      File.delete(File.expand_path('../../test_folder/test_sub_folder/test_file_one.txt.enc',  __FILE__))
      File.delete(File.expand_path('../../test_folder/test_sub_folder/test_file_one.txt.dec',  __FILE__))
    end
  end
end
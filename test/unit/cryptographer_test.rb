require 'test_helper'
#require File.expand_path('../../../lib/master', __FILE__)

require 'openssl'

class CryptographerTest < ActiveSupport::TestCase
  
  def setup
    @test_file_path = File.expand_path('../../test_folder/test_sub_folder/test_file_one.txt',  __FILE__)
  end
  
  test 'should hash file' do
    hash = Cryptographer.hash_file(File.expand_path('../../test_folder/test_sub_folder/test_file_one.txt',  __FILE__))
    assert_equal(Digest::SHA2,hash.class)
  end
  
  test 'should encrypt string' do
    assert_equal('28c7cdd41ac00d41b59a2f930bef1d384c9510d77b15d61825b41e345ddec8829f0ea295cbadf839ca937601e4d0b2669bff2f7e984cee25651eb8cf440c6f99', Cryptographer.encrypt_string('testing 123'))
  end
  
  test 'should encrypt and decrypt file' do
    begin
      encrypted_file_path = "#{File.expand_path('../../../temp',  __FILE__)}/#{File.basename(@test_file_path)}.encrypted"
      assert_equal(false,File.exist?(encrypted_file_path))
      Cryptographer.encrypt_file(@test_file_path)
      assert_equal(true,File.exist?(encrypted_file_path))
      decrypted_file_path = Cryptographer.decrypt_file(encrypted_file_path)
      assert_equal(File.open(@test_file_path,'rb').read,File.open(decrypted_file_path,'rb').read)
    ensure
      File.delete(encrypted_file_path) if File.exist?(encrypted_file_path)
    end
  end
  
end

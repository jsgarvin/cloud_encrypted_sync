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
    assert_equal('885e57411c7df4fa3b2881410cffd0969cdb700fcce168d2b3addcdec34603ff2ba40e078bb4012a4654bac01f7481049d5aa015aff554935ed8aa967a7728de', Cryptographer.encrypt_string('testing 123'))
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

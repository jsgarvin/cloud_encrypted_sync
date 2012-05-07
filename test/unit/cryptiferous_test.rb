require File.expand_path('../../../lib/cryptiferous', __FILE__)
require 'test_helper'
require 'openssl'

class CryptiferousTest < ActiveSupport::TestCase
  
  def setup
    @test_file_path = File.expand_path('../../test_folder/test_sub_folder/test_file_one.txt',  __FILE__)
  end
  
  def test_should_generate_directory_hash
    hash = Cryptiferous.directory_hash
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
      
      hash = Cryptiferous.directory_hash
      
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
  
  def test_should_encrypt_string
    assert_equal('28c7cdd41ac00d41b59a2f930bef1d384c9510d77b15d61825b41e345ddec8829f0ea295cbadf839ca937601e4d0b2669bff2f7e984cee25651eb8cf440c6f99', Cryptiferous.encrypt_string('testing 123'))
  end
  
  def test_should_encrypt_file
    begin
      encrypted_file_path = "#{File.expand_path('../../../temp',  __FILE__)}/#{File.basename(@test_file_path)}.encrypted"
      assert_equal(false,File.exist?(encrypted_file_path))
      Cryptiferous.encrypt_file(@test_file_path)
      assert_equal(true,File.exist?(encrypted_file_path))
    ensure
      File.delete(encrypted_file_path) if File.exist?(encrypted_file_path)
    end
  end
  
  def test_should_return_nil_if_never_synced_before
    assert_equal(nil,Cryptiferous.last_sync_date)
  end
  
  def test_should_want_to_push_everything_on_first_run
    assert_equal(Cryptiferous.directory_hash,Cryptiferous.files_to_push)
  end
  
  def test_should_only_want_to_push_new_files_on_later_run
    new_file_path = "#{Cryptiferous.base_path}test_should_only_want_to_push_new_files_on_later_run.txt"
    begin
      Cryptiferous.generate_directory_file
      File.open(new_file_path,'w') do |file|
        file.write "This is only a test."
      end
      assert_equal({"9973a0d1729566f34377e90cea4a40c0c1106d55baf2a3e0127ddcad4015962d"=> "test_should_only_want_to_push_new_files_on_later_run.txt"},Cryptiferous.files_to_push)
    ensure
      File.delete(new_file_path) if File.exist?(new_file_path)
    end
  end
  
  def test_should_want_to_pull_new_files_from_s3
    assert false
  end
  
  def test_should_want_to_delete_locally_missing_files_from_s3
    assert false
  end
  
  def test_should_want_to_delete_appropriate_files_locally
    assert false
  end
end
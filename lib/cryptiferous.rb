require 'find'
require 'digest'
require 'yaml'

class Cryptiferous
  CONFIG = YAML.load_file(File.expand_path('../../config/config.yml',  __FILE__))
  ALG = 'AES-128-CBC'
  
  class << self
    
    def directory_hash(root_path)
      root_path += '/' unless root_path.match(/\/$/)
      directory = {}
      Find.find(root_path) do |path|
        if FileTest.directory?(path)
          next
        else
          short_path = path.gsub(root_path,'')
          directory[hash_file(path).to_s] = short_path
        end
      end
      return directory
    end
    
    def hash_file(path)
      sha1 = Digest::SHA2.new
      File.open(path) do |file|
        buffer = ''
        while not file.eof
          file.read(512, buffer)
          sha1.update(buffer)
        end
      end
      return sha1
    end
    
    def encrypt_file(path)
      aes = OpenSSL::Cipher::Cipher.new(ALG)
      aes.encrypt
      aes.key = CONFIG['encryption_key']
      aes.iv = CONFIG['initialization_vector']
      
      encrypted_file_path = "#{File.expand_path('../../temp',  __FILE__)}/#{File.basename(path)}.enc"
      File.open(encrypted_file_path,'w') do |encrypted_file|
        File.open(File.expand_path(path,  __FILE__)) do |unencrypted_file|
          while data = unencrypted_file.read(4096)
            encrypted_file << aes.update(data)
          end
          encrypted_file << aes.final
        end
      end
    end
  end
end

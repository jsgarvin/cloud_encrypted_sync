require 'find'
require 'digest'

class Cryptiferous
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
      aes.key = S3::CONFIG['encryption_key']
      aes.iv = S3::CONFIG['initialization_vector']
      
      File.open(File.expand_path(path + '.enc',  __FILE__),'w') do |encrypted_file|
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

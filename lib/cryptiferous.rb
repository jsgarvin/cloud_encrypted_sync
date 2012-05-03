require 'find'
require 'digest'
require 'yaml'

class Cryptiferous
  CONFIG = YAML.load_file(File.expand_path('../../config/config.yml',  __FILE__))
  ALG = 'AES-256-CBC'
  
  class << self
    
    def directory_hash
      directory = {}
      Find.find(base_path) do |this_path|
        if FileTest.directory?(this_path)
          next
        else
          relative_path = this_path.gsub(base_path,'')
          directory[hash_file(this_path).to_s] = relative_path
        end
      end
      return directory
    end
    
    def directory_key
      @directory_key ||= encrypt_string('DirectoryFile')
    end
    
    def generate_directory_file
      path = File.expand_path("../../temp/directory_structure.yml", __FILE__)
      File.open(path, 'w') do |directory_file|
        directory_file.write(Cryptiferous.directory_hash.to_yaml)
      end
      return path
    end
    
    def decrypt_directory_file(data)
      path = File.expand_path("../../temp/directory_structure.yml.encrypted", __FILE__)
      File.open(path, 'w') do |directory_file|
        directory_file.write(data)
      end
      decrypted_path = decrypt_file(path)
      File.delete(path)
      hash = YAML.load(File.read(decrypted_path))
      File.delete(decrypted_path)
      return hash
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
    
    def crypt_file(direction,path)
      cipher = setup_cipher(direction)
      crypted_file_path = "#{File.expand_path('../../temp',  __FILE__)}/#{File.basename(path)}.#{direction}ed"
      
      File.open(crypted_file_path,'w') do |crypted_file|
        File.open(File.expand_path(path,  __FILE__)) do |precrypted_file|
          while data = precrypted_file.read(4096)
            crypted_file << cipher.update(data)
          end
          crypted_file << cipher.final
        end
      end
      return crypted_file_path
    end
    
    def encrypt_file(path)
      crypt_file(:encrypt, path)
    end
    
    def decrypt_file(path)
      crypt_file(:decrypt, path)
    end
    
    def encrypt_string(string)
      cipher = setup_cipher(:encrypt)
      encrypted_string = cipher.update(string)
      encrypted_string << cipher.final
      return hash_string(encrypted_string.to_s)
    end
    
    def hash_string(string)
      Digest::SHA2.hexdigest(string,512)
    end
    
    def base_path
      if @base_path.nil?
        @base_path = CONFIG['base_path']
        @base_path += '/' unless @base_path.match(/\/$/)
      end
      return @base_path
    end
    
    #######
    private
    #######
    
    def setup_cipher(crypt)
      cipher = OpenSSL::Cipher::Cipher.new(ALG)
      cipher.send(crypt)
      cipher.key = hash_string(CONFIG['encryption_key'])
      cipher.iv = hash_string(CONFIG['initialization_vector'])
      return cipher
    end
  end
end

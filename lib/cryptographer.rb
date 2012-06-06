class Cryptographer
  
  class << self
    ALGORITHM = 'AES-256-CBC'
    
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
    
    #######
    private
    #######
    
    def setup_cipher(crypt)
      cipher = OpenSSL::Cipher::Cipher.new(ALGORITHM)
      cipher.send(crypt)
      cipher.key = hash_string(Master.config['encryption_key'])
      cipher.iv = hash_string(Master.config['initialization_vector'])
      return cipher
    end
    
    def crypt_file(direction,path)
      cipher = setup_cipher(direction)
      crypted_file_path = "#{File.expand_path('../../temp',  __FILE__)}/#{File.basename(path)}.#{direction}ed"
      
      File.open(crypted_file_path,'w') do |crypted_file|
        File.open(File.expand_path(path,  __FILE__),'rb') do |precrypted_file|
          while data = precrypted_file.read(4096)
            crypted_file << cipher.update(data)
          end
          crypted_file << cipher.final
        end
      end
      return crypted_file_path
    end
    
  end
  
end
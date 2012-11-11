require 'openssl'
require 'digest'

module CloudEncryptedSync
  class Cryptographer
    ALGORITHM = 'AES-256-CBC'

    class << self


      def encrypt_data(data)
        iv = generate_random_iv
        encrypted_data = crypt_data(:encrypt, iv, data)
        return iv + encrypted_data
      end

      def decrypt_data(ivdata)
        iv= ivdata.byteslice(0..15)
        data = ivdata.byteslice(16..-1)
        crypt_data(:decrypt, iv, data)
      end

      def hash_data(data)
        Digest::SHA2.hexdigest(data,512)
      end

      def generate_random_key
        initialized_cipher.random_key.unpack('H*')[0]
      end

      #######
      private
      #######

      def generate_random_iv
        initialized_cipher.random_iv
      end

      def initialized_cipher(crypt = nil)
        cipher = OpenSSL::Cipher::Cipher.new(ALGORITHM)
        cipher.send(crypt) if crypt
        return cipher
      end

      def setup_cipher(crypt,iv)
        cipher = initialized_cipher(crypt)
        cipher.key = hash_data(Configuration.settings[:encryption_key])
        cipher.iv = iv
        return cipher
      end

      def crypt_data(direction,iv,precrypted_data)
        cipher = setup_cipher(direction,iv)
        crypted_data = cipher.update(precrypted_data)
        crypted_data << cipher.final
        return crypted_data
      end
    end

  end
end
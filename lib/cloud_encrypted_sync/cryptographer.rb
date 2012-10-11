module CloudEncryptedSync
  class Cryptographer

    class << self
      ALGORITHM = 'AES-256-CBC'

      def encrypt_data(data)
        crypt_data(:encrypt, data)
      end

      def decrypt_data(data)
        crypt_data(:decrypt, data)
      end

      def encrypt_string(string)
        encrypted_string = encrypt_data(string)
        return hash_data(encrypted_string.to_s)
      end

      def hash_data(data)
        Digest::SHA2.hexdigest(data,512)
      end

      def generate_random_key
        initialize_cipher(:encrypt).random_key.unpack('H*')[0]
      end

      def generate_random_iv
        initialize_cipher(:encrypt).random_iv.unpack('H*')[0]
      end

      #######
      private
      #######

      def initialize_cipher(crypt)
        cipher = OpenSSL::Cipher::Cipher.new(ALGORITHM)
        cipher.send(crypt)
        return cipher
      end

      def setup_cipher(crypt)
        cipher = initialize_cipher(crypt)
        cipher.key = hash_data(Master.config[:encryption_key])
        cipher.iv = hash_data(Master.config[:initialization_vector])
        return cipher
      end

      def crypt_data(direction,precrypted_data)
        cipher = setup_cipher(direction)
        crypted_data = cipher.update(precrypted_data)
        crypted_data << cipher.final
        return crypted_data
      end
    end

  end
end
require 'find'
require 'digest'
require 'yaml'
require 'cryptographer'
require 's3_liason'

class Master
  
  class << self
    
    def config
      @config ||= YAML.load_file(File.expand_path('../../config/config.yml',  __FILE__))
    end
    
    def directory_hash
      directory_hash = {}
      Find.find(base_path) do |this_path|
        if FileTest.directory?(this_path)
          next
        else
          relative_path = this_path.gsub(base_path,'')
          directory_hash[Cryptographer.hash_file(this_path).to_s] = relative_path
        end
      end
      return directory_hash
    end
    
    def directory_key
      @directory_key ||= Cryptographer.hash_string(config['encryption_key'])
    end
    
    def generate_directory_file
      File.open(directory_file_path, 'w') do |directory_file|
        directory_file.write(directory_hash.to_yaml)
      end
      return Cryptographer.encrypt_file(directory_file_path)
    end
    
    def decrypt_directory_file(data)
      path = File.expand_path("../../temp/directory_structure.yml.encrypted", __FILE__)
      File.open(path, 'w') do |directory_file|
        directory_file.write(data)
      end
      decrypted_path = Cryptographer.decrypt_file(path)
      File.delete(path)
      hash = YAML.load(File.read(decrypted_path))
      File.delete(decrypted_path)
      return hash
    end
    
    def base_path
      if @base_path.nil?
        @base_path = config['base_path']
        @base_path += '/' unless @base_path.match(/\/$/)
      end
      return @base_path
    end
    
    def last_sync_date
      @last_sync_date ||= File.exist?(directory_file_path) ? File.stat(directory_file_path).ctime : nil
    end
    
    def last_sync_hash
      @last_sync_hash ||= File.exist?(directory_file_path) ? YAML.load(File.read(directory_file_path)) : {}
    end
    
    def files_to_push
      directory_hash.select{|k,v| !last_sync_hash.has_key?(k) and !remote_directory_hash.has_key?(k) }
    end
    
    def files_to_pull
      remote_directory_hash.select{|k,v| !directory_hash.has_key?(k) and !last_sync_hash.has_key?(k) }
    end
    
    def remote_files_to_delete
      remote_directory_hash.select{|k,v| !directory_hash.has_key?(k) and last_sync_hash.has_key?(k) }
    end
    
    def local_files_to_delete
      directory_hash.select{|k,v| !remote_directory_hash.has_key?(k) and last_sync_hash.has_key?(k) }
    end
    
    def remote_directory_hash
      decrypt_directory_file(S3Liason.read(directory_key))
    end
    
    def store_directory_hash_file
      encrypted_file_path = generate_directory_file
      S3Liason.write(encrypted_file_path,directory_key)
      File.delete(encrypted_file_path)
    end
    
    #######
    private
    #######
    
    def directory_file_path
      "#{data_directory}/folder_snapshot.yml"
    end
    
    def data_directory
      return @data_directory if @data_directory
      @data_directory = "#{ENV['HOME']}/.cloud_encrypted_sync"
      FileUtils.mkdir_p(@data_directory)
    end
    
  end
end

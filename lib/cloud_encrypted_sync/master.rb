require 'find'
require 'digest'
require 'yaml'

module CloudEncryptedSync
  class Master
    
    class << self
      attr_accessor :command_line_options
      attr_writer   :sync_path

      def config
        if @config
          return @config
        else
          @config = {}
          FileUtils.mkdir_p(data_folder_path) unless Dir.exists?(data_folder_path)
          @config = YAML.load_file(config_file_path) if File.exist?(config_file_path)
          @config.merge!(command_line_options)
          #symbolize keys
          @config = @config.inject({}) do |options, (key, value)|
            options[(key.to_sym rescue key) || key] = value
            options
          end
        end
      end
      
      def directory_hash
        directory_hash = {}
        Find.find(sync_path) do |this_path|
          if FileTest.directory?(this_path)
            next
          else
            relative_path = this_path.gsub(sync_path,'')
            directory_hash[Cryptographer.hash_data(File.open(this_path).read).to_s] = relative_path
          end
        end
        return directory_hash
      end
      
      def directory_key
        @directory_key ||= Cryptographer.hash_data(config[:encryption_key])
      end
      
      def sync_path
        return @modified_sync_path if @modified_sync_path
        @modified_sync_path = @sync_path
        @modified_sync_path += '/' unless @modified_sync_path.match(/\/$/)
        return @modified_sync_path
      end
      
      def last_sync_date
        @last_sync_date ||= File.exist?(snapshot_file_path) ? File.stat(snapshot_file_path).ctime : nil
      end
      
      def last_sync_hash
        @last_sync_hash ||= File.exist?(snapshot_file_path) ? YAML.load(File.read(snapshot_file_path)) : {}
      end
      
      def files_to_push
        syncable_files_check(directory_hash,remote_directory_hash)
      end
      
      def files_to_pull
        syncable_files_check(remote_directory_hash,directory_hash)
      end
      
      def remote_files_to_delete
        deletable_files_check(remote_directory_hash,directory_hash)
      end
      
      def local_files_to_delete
        deletable_files_check(directory_hash,remote_directory_hash)
      end
      
      def remote_directory_hash
        YAML.parse(Cryptographer.decrypt_data(S3Liason.read(directory_key))).to_ruby
      end
      
      def store_directory_hash_file
        S3Liason.write(Cryptographer.encrypt_data(directory_hash.to_yaml),directory_key)
      end
      
      #######
      private
      #######
      
      def deletable_files_check(source_hash,comparison_hash)
        combined_file_check(source_hash,comparison_hash,true)
      end

      def syncable_files_check(source_hash,comparison_hash)
        combined_file_check(source_hash,comparison_hash,false)
      end

      def combined_file_check(source_hash,comparison_hash,last_sync_has_key)
        source_hash.select{|k,v| !comparison_hash.has_key?(k) and (last_sync_has_key ? last_sync_hash.has_key?(k) : !last_sync_hash.has_key?(k)) }
      end

      def snapshot_file_path
        "#{data_folder_path}/#{snapshot_filename}"
      end
      
      def snapshot_filename
        "#{sync_path.gsub(/[^A-Za-z0-9]/,'_')}.snapshot.yml"
      end
      
      def data_folder_path
        command_line_options[:data_dir]
      end

      def config_file_path
        data_folder_path+'/config.rc.yml'
      end

    end
  end
end
require 'find'
require 'digest'
require 'yaml'

module CloudEncryptedSync
  class Master
    
    class << self
      attr_accessor :finalize_required
      attr_reader   :command_line_options
      attr_writer   :sync_path

      def config
        if @config
          return @config
        else
          @config = {}
          FileUtils.mkdir_p(data_folder_path) unless Dir.exists?(data_folder_path)
          @config = YAML.load_file(config_file_path) if File.exist?(config_file_path)
          @config.merge!(command_line_options)
          @config = @config.inject({}) do |options, (key, value)|
            options[(key.to_sym rescue key) || key] = value
            options
          end
        end
      end
      
      def parse_command_line_options
        return if @command_line_options
        @command_line_options = {:data_dir => "#{Etc.getpwuid.dir}/.cloud_encrypted_sync"}

        option_parser = OptionParser.new do |opts|
          opts.banner = "Usage: #{executable_name} [options] /path/to/folder/to/sync [ENCRYPTION KEY] [INITIALIZATION VECTOR]"
          opts.on('--data-dir PATH',"Data directory where snapshots and config file are found. Defaults to '#{options[:datadir]}'") do |path|
            @command_line_options[:data_dir] = path
          end
          opts.on('--s3-credentials ACCESS_KEY_ID,SECRET_ACCESS_KEY', Array, "Credentials for your S3 account." ) do| credentials|
            @command_line_options[:s3_credentials] = credentials
          end
          opts.on('--s3-bucket BUCKETNAME', 'Name of bucket to use on S3.') do |bucket|
            @command_line_options[:s3_bucket] = bucket
          end
          opts.on('--encryption-key KEY') do |key|
            @command_line_options[:encryption_key] = key
          end
          opts.on('--initialization-vector VECTOR') do |vector|
            @command_line_options[:initialization_vector] = vector
          end
        end
        option_parser.parse!
      end


      def directory_hash
        return @directory_hash if @directory_hash
        @directory_hash = {}
        puts "Compiling Directory Analysis"
        Find.find(sync_path) do |path|
          if FileTest.directory?(path)
            next
          else
            @directory_hash[file_key(path)] = relative_file_path(path)
          end
        end
        return @directory_hash
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
      
      def push_files!
        files_to_push.each_pair  do |key,relative_path| 
          if S3Liason.key_exists?(key)
            #already exists. probably left over from an earlier aborted push
            puts "Not Pushing (already exists): #{relative_path}"
          else
            puts "Pushing: #{relative_path}"
            S3Liason.write(File.read(full_file_path(relative_path)),key)
            self.finalize_required = true
          end
        end
      end

      def files_to_pull
        syncable_files_check(remote_directory_hash,directory_hash)
      end

      def pull_files!
        files_to_pull.each_pair do |key,relative_path|
          full_path = full_file_path(relative_path)
          if File.exist?(full_path) and (file_key(full_path) == key)
            #already exists. probably left over from an earlier aborted pull
            puts "Not Pulling (already exists): #{path}"
          else
            Dir.mkdir(File.dirname(full_path)) unless File.exist?(File.dirname(full_path))
            puts "Pulling: #{relative_path}"
            begin
              File.write(full_path,S3Liason.read(key))
              self.finalize_required = true
            rescue AWS::S3::Errors::NoSuchKey
              puts "Failed to pull #{relative_path}"
            end
          end
        end
      end

      def remote_files_to_delete
        deletable_files_check(remote_directory_hash,directory_hash)
      end
      
      def delete_remote_files!
        remote_files_to_delete.each_pair do |key,path|
          puts "Deleting Remote: #{path}"
          S3Liason.delete(key)
          self.finalize_required = true
        end
      end

      def local_files_to_delete
        deletable_files_check(directory_hash,remote_directory_hash)
      end

      def delete_local_files!
        local_files_to_delete.each_pair do |key,relative_path| 
          full_path = full_file_path(relative_path)
          if !File.exist?(full_path) or (file_key(full_path) == key)
            puts "Not Deleting Local: #{relative_path}"
          else
            puts "Deleting Local: #{relative_path}"
            File.delete(full_path)
            self.finalize_required = true
          end
        end
      end

      def remote_directory_hash
        @remote_directory_hash ||= begin
          YAML.parse(Cryptographer.decrypt_data(S3Liason.read(directory_key))).to_ruby
        rescue AWS::S3::Errors::NoSuchKey
          {}
        end
      end
      
      def store_directory_hash_file
        @directory_hash = nil #force re-compile before pushing to remote
        S3Liason.write(Cryptographer.encrypt_data(directory_hash.to_yaml),directory_key)
      end
      
      def finalize!
        if finalize_required
          store_directory_hash_file
          File.open(snapshot_file_path, 'w') { |file| YAML.dump(directory_hash, file) }
        end
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
      
      def file_key(full_path)
        Cryptographer.hash_data(relative_file_path(full_path) + File.open(full_path).read).to_s
      end

      def relative_file_path(full_path)
        full_path.gsub(sync_path,'')
      end

      def full_file_path(relative_path)
        sync_path+'/'+relative_path
      end
    end
  end
end
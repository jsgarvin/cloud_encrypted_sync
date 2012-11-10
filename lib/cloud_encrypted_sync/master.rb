require 'find'
require 'active_support/core_ext/string'

module CloudEncryptedSync
  class Master

    class << self
      attr_accessor :finalize_required
      attr_reader   :command_line_options, :adapters
      attr_writer   :sync_path

      def register(adapter)
        @adapters ||= {}
        name = adapter.name.match(/([^:]+)$/)[0].underscore.to_sym
        raise RegistrationError, "#{name} already registered" if @adapters[name]
        @adapters[name] = adapter
      end

      def activate!
        find_and_require_adapters
        sync
      end

      def sync
        begin
          CloudEncryptedSync::Master.delete_local_files!
          CloudEncryptedSync::Master.delete_remote_files!
          CloudEncryptedSync::Master.pull_files!
          CloudEncryptedSync::Master.push_files!
          CloudEncryptedSync::Master.finalize!
        rescue IncompleteConfigurationError => exception
          puts exception.message
        end
      end

      def push_files!
        progress_meter = ProgressMeter.new(files_to_pull.keys.size,:label => 'Pushing Files: ')
        pushed_files_counter = 0
        files_to_push.each_pair do |key,relative_path|
          if adapter.key_exists?(key)
            #already exists. probably left over from an earlier aborted push
            puts "Not Pushing (already exists): #{relative_path}"
          else
            puts "Pushing: #{relative_path}"
            write_to_adapter(File.read(full_file_path(relative_path)),key)
            self.finalize_required = true
          end
          pushed_files_counter += 1
          print progress_meter.update(pushed_files_counter)
        end
      end

      def pull_files!
        progress_meter = ProgressMeter.new(files_to_pull.keys.size,:label => 'Pulling Files: ')
        pulled_files_counter = 0
        files_to_pull.each_pair do |key,relative_path|
          full_path = full_file_path(relative_path)
          if File.exist?(full_path) and (file_key(full_path) == key)
            #already exists. probably left over from an earlier aborted pull
            puts "Not Pulling (already exists): #{path}"
          else
            Dir.mkdir(File.dirname(full_path)) unless File.exist?(File.dirname(full_path))
            puts "Pulling: #{relative_path}"
            begin
              File.open(full_path,'w') { |file| file.write(read_from_adapter(key)) }
              self.finalize_required = true
            rescue #AWS::S3::Errors::NoSuchKey  Should provide error for adapters to raise
              puts "Failed to pull #{relative_path}"
            end
          end
          pulled_files_counter += 1
          print progress_meter.update(pulled_files_counter)
        end
      end

      def delete_remote_files!
        remote_files_to_delete.each_pair do |key,path|
          puts "Deleting Remote: #{path}"
          adapter.delete(key)
          self.finalize_required = true
        end
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

      def finalize!
        if finalize_required
          store_directory_hash_file
          File.open(snapshot_file_path, 'w') { |file| YAML.dump(directory_hash, file) }
        end
      end

      #######
      private
      #######

      def find_and_require_adapters
        latest_versions_of_installed_adapters.each_pair do |adapter_name,adapter_version|
          require File.expand_path("../../../../cloud_encrypted_sync_#{adapter_name}_adapter-#{adapter_version}", __FILE__)
        end
      end

      def latest_versions_of_installed_adapters
        glob_path = '../../../../cloud_encrypted_sync_*_adapter-*/lib/*.rb'
        Dir.glob(File.expand_path(glob_path,__FILE__)).inject({}) do |hash,adapter_path|
          if adapter_path.match(/cloud_encrypted_sync_(.+)_adapter-(.+)/)
            adapter_name = $1
            adapter_version = $2
            if hash[adapter_name].to_s < adapter_version
              hash[adapter_name] = adapter_version
            end
          end
          hash
        end
      end

      def adapter
        @adapters[Configuration.settings[:adapter_name].to_sym]
      end

      def write_to_adapter(data,key)
        adapter.write(Cryptographer.encrypt_data(data),key)
      end

      def read_from_adapter(key)
        Cryptographer.decrypt_data(adapter.read(key))
      end

      def directory_hash
        return @directory_hash if @directory_hash
        @directory_hash = {}
        progress_meter = ProgressMeter.new(Dir["#{normalized_sync_path}/**/*"].length,:label => 'Compiling Directory Analysis: ')
        completed_files = 0
        Find.find(normalized_sync_path) do |path|
          print progress_meter.update(completed_files)
          if FileTest.directory?(path)
            completed_files += 1
            next
          else
            @directory_hash[file_key(path)] = relative_file_path(path)
            completed_files += 1
          end
        end
        puts
        return @directory_hash
      end

      def directory_key
        @directory_key ||= Cryptographer.hash_data(Configuration.settings[:encryption_key])
      end

      def normalized_sync_path
        @normalized_sync_path ||= normalize_sync_path
      end

      def normalize_sync_path
        path = Configuration.settings[:sync_path]
        if path.match(/\/$/)
          return path
        else
          return path + '/'
        end
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
        @remote_directory_hash ||= begin
          YAML.parse(Cryptographer.decrypt_data(read_from_adapter(directory_key))).to_ruby
        rescue #AWS::S3::Errors::NoSuchKey  should provide error for adapters to raise
          {}
        end
      end

      def store_directory_hash_file
        @directory_hash = nil #force re-compile before pushing to remote
        write_to_adapter(Cryptographer.encrypt_data(directory_hash.to_yaml),directory_key)
      end

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
        "#{Configuration.data_folder_path}/#{snapshot_filename}"
      end

      def snapshot_filename
        "#{normalized_sync_path.gsub(/[^A-Za-z0-9]/,'_')}.snapshot.yml"
      end

      def file_key(full_path)
        Cryptographer.hash_data(relative_file_path(full_path) + File.open(full_path).read).to_s
      end

      def relative_file_path(full_path)
        full_path.gsub(normalized_sync_path,'')
      end

      def full_file_path(relative_path)
        normalized_sync_path+'/'+relative_path
      end
    end
  end

  class RegistrationError < RuntimeError; end
end
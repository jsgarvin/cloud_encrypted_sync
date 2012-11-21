module CloudEncryptedSync
  class Synchronizer

    class << self
      attr_accessor :finalize_required

      def run
        begin
          delete_local_files
          delete_remote_files
          pull_files
          push_files
          finalize
        rescue Errors::IncompleteConfigurationError => exception
          puts exception.message
        end
      end

      #######
      private
      #######

      def push_files
        ProgressMeter.new(files_to_push.keys.size,:label => 'Pushing Files: ') do |progress_meter|
          pushed_files_counter = 0
          files_to_push.each_pair do |key,relative_path|
            push_file_if_necessary(key,relative_path)
            progress_meter.increment_completed_index
          end
        end
      end

      def push_file_if_necessary(key,relative_path)
        if liaison.key_exists?(key)
          #already exists. probably left over from an earlier aborted push
          puts "\nNot Pushing (already exists): #{relative_path}"
        else
          puts "\nPushing: #{relative_path}"
          liaison.push(File.read(Index.full_file_path(relative_path)),key)
          self.finalize_required = true
        end
      end

      def pull_files
        ProgressMeter.new(files_to_pull.keys.size,:label => 'Pulling Files: ') do |progress_meter|
          files_to_pull.each_pair do |key,relative_path|
            pull_file_if_necessary(key,relative_path)
            progress_meter.increment_completed_index
          end
        end
      end

      def pull_file_if_necessary(key,relative_path)
        full_path = Index.full_file_path(relative_path)
        if File.exist?(full_path) and (Index.file_key(full_path) == key)
          #already exists. probably left over from an earlier aborted pull
          puts "\nNot Pulling (already exists): #{full_path}"
        else
          Dir.mkdir(File.dirname(full_path)) unless File.exist?(File.dirname(full_path))
          puts "\nPulling: #{relative_path}"
          pull_file_or_rescue(key,relative_path)
        end
      end

      def pull_file_or_rescue(key,relative_path)
        full_path = Index.full_file_path(relative_path)
        begin
          File.open(full_path,'w') { |file| file.write(liaison.pull(key)) }
          self.finalize_required = true
        rescue Errors::NoSuchKey
          puts "\nFailed to pull #{relative_path}"
        end
      end

      def delete_remote_files
        remote_files_to_delete.each_pair do |key,path|
          puts "Deleting Remote: #{path}"
          liaison.delete(key)
          self.finalize_required = true
        end
      end

      def delete_local_files
        local_files_to_delete.each_pair do |key,relative_path|
          full_path = Index.full_file_path(relative_path)
          if !File.exist?(full_path)
            puts "Not Deleting Local: #{relative_path}"
          else
            puts "Deleting Local: #{relative_path}"
            File.delete(full_path)
            self.finalize_required = true
          end
        end
      end

      def finalize
        Index.write if finalize_required
      end

      def liaison
        AdapterLiaison.instance
      end

      def last_sync_hash
        @last_sync_hash ||= File.exist?(Index.index_path) ? YAML.load(File.read(Index.index_path)) : {}
      end

      def files_to_push
        syncable_files_check(Index.local,Index.remote)
      end

      def files_to_pull
        syncable_files_check(Index.remote,Index.local)
      end

      def remote_files_to_delete
        deletable_files_check(Index.remote,Index.local)
      end

      def local_files_to_delete
        deletable_files_check(Index.local,Index.remote)
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

    end
  end
end
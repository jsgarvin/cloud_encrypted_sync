module CloudEncryptedSync
  class Index

    class << self

      def local
        @local ||= compile_local_hash
      end

      def remote
        @remote ||= begin
          YAML.parse(liaison.pull(index_key)).to_ruby
        rescue Errors::NoSuchKey
          {}
        end
      end

      def write
        local_hash = compile_local_hash #recompile
        liaison.push(local_hash.to_yaml,index_key) #push to remote
        File.open(snapshot_path, 'w') { |file| YAML.dump(local_hash, file) } #save to local
      end

      def full_file_path(relative_path)
        normalized_sync_path+'/'+relative_path
      end

      def snapshot_path
        "#{Configuration.data_folder_path}/#{snapshot_filename}"
      end

      def file_key(full_path)
        Cryptographer.hash_data(relative_file_path(full_path) + File.open(full_path).read).to_s
      end

      #######
      private
      #######

      def liaison
        AdapterLiaison.instance
      end

      def compile_local_hash
        hash = {}
        progress_meter = ProgressMeter.new(Dir["#{normalized_sync_path}/**/*"].length,:label => 'Compiling Local Index: ')
        completed_files = 0
        Find.find(normalized_sync_path) do |path|
          print progress_meter.update(completed_files)
          unless FileTest.directory?(path)
            hash[file_key(path)] = relative_file_path(path)
          end
          completed_files += 1
        end
        puts #newline for progress meter
        return hash
      end

      def index_key
        @index_key ||= Cryptographer.hash_data(Configuration.settings[:encryption_key])
      end

      def snapshot_filename
        "#{normalized_sync_path.gsub(/[^A-Za-z0-9]/,'_')}.index.yml"
      end

      def relative_file_path(full_path)
        full_path.gsub(normalized_sync_path,'')
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

    end
  end
end
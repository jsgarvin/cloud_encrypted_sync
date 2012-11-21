module CloudEncryptedSync
  class Configuration

    class << self

      attr_reader :option_parser

      def settings
        @settings ||= load
      end

      def data_folder_path
        command_line_options[:data_dir]
      end

      #######
      private
      #######

      def load
        touch_data_folder
        loaded_settings = config_file_settings.merge(command_line_options).with_indifferent_access

        loaded_settings[:sync_path] = ARGV.shift unless ARGV.empty?

        validate_settings(loaded_settings)

        return loaded_settings
      end

      def config_file_settings
        @config_file_settings ||= load_config_file_settings
      end

      def load_config_file_settings
        if File.exist?(config_file_path)
          YAML.load_file(config_file_path)
        else
          {}
        end
      end

      def validate_settings(loaded_settings)
        if loaded_settings[:sync_path].nil?
          message = "You must supply a path to a folder to sync.\n\n#{option_parser.help}"
          raise Errors::IncompleteConfigurationError.new(message)
        elsif loaded_settings[:encryption_key].nil? or loaded_settings[:encryption_key].empty?
          message = "You must supply an encryption key.\n\n#{option_parser.help}"
          raise Errors::IncompleteConfigurationError.new(message)
        end
      end

      def touch_data_folder
        FileUtils.mkdir_p(data_folder_path) unless Dir.exists?(data_folder_path)
      end

      def config_file_path
        data_folder_path+'/config.rc.yml'
      end

      def command_line_options
        @command_line_options ||= parse_command_line_options
      end

      def parse_command_line_options
        executable_name = File.basename($PROGRAM_NAME)
        clo = {:data_dir => "#{Etc.getpwuid.dir}/.cloud_encrypted_sync"}

        @option_parser = OptionParser.new do |parser|
          parser.banner = "Usage: #{executable_name} [options] /path/to/folder/to/sync"
          parser.on('--data-dir PATH',"Data directory where indexes and config file are found.") do |path|
            clo[:data_dir] = path
          end
          parser.on('--adapter ADAPTERNAME', 'Name of cloud adapter to use.') do |adapter_name|
            clo[:adapter_name] = adapter_name
            AdapterLiaison.instance.adapters[adapter_name.to_sym].parse_command_line_options(parser)
          end
          parser.on('--encryption-key KEY') do |key|
            clo[:encryption_key] = key
          end
        end
        @option_parser.parse!

        return clo
      end

    end
  end
end
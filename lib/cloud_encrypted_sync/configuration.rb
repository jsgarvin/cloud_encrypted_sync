require 'yaml'

module CloudEncryptedSync
  class Configuration

    class << self

      attr_reader :option_parser

      def settings
        @settings ||= load_settings
      end

      def data_folder_path
        command_line_options[:data_dir]
      end

      #######
      private
      #######

      def load_settings
        touch_data_folder
        loaded_settings = {}
        loaded_settings = YAML.load_file(config_file_path) if File.exist?(config_file_path)
        loaded_settings.merge!(command_line_options)
        loaded_settings = loaded_settings.inject({}) do |options, (key, value)|
          options[(key.to_sym rescue key) || key] = value
          options
        end
        loaded_settings[:sync_path] = ARGV.shift unless ARGV.empty?

        if loaded_settings[:sync_path].nil?
          message = "You must supply a path to a folder to sync.\n\n#{option_parser.help}"
          raise Errors::IncompleteConfigurationError.new(message)
        elsif loaded_settings[:encryption_key].nil? or loaded_settings[:encryption_key].empty?
          message = "You must supply an encryption key.\n\n#{option_parser.help}"
          raise Errors::IncompleteConfigurationError.new(message)
        end

        return loaded_settings
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

        @option_parser = OptionParser.new do |opts|
          opts.banner = "Usage: #{executable_name} [options] /path/to/folder/to/sync"
          opts.on('--data-dir PATH',"Data directory where snapshots and config file are found.") do |path|
            clo[:data_dir] = path
          end
          opts.on('--adapter ADAPTERNAME', 'Name of cloud adapter to use.') do |adapter_name|
            clo[:adapter_name] = adapter_name
            clo = AdapterLiaison.instance.adapters[adapter_name.to_sym].parse_command_line_options(opts,clo)
          end
          opts.on('--encryption-key KEY') do |key|
            clo[:encryption_key] = key
          end
        end
        @option_parser.parse!

        return clo
      end

    end
  end
end
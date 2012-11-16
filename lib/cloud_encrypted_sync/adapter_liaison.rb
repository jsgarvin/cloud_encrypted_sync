module CloudEncryptedSync
  class AdapterLiaison
    include Singleton
    attr_reader :adapters

    def initialize
      @adapters = {}
      find_and_require_adapters
    end

    def register(adapter)
      name = adapter.name.match(/([^:]+)$/)[0].underscore.to_sym
      if @adapters[name]
        raise Errors::RegistrationError.new("#{name} already registered")
      else
        @adapters[name] = adapter
      end
    end

    def push(data,key)
      adapter.write(Cryptographer.encrypt_data(data),key)
    end

    def pull(key)
      Cryptographer.decrypt_data(adapter.read(key))
    end

    def delete(key)
      adapter.delete(key)
    end

    def key_exists?(key)
      adapter.key_exists?(key)
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
  end
end
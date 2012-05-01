require 'find'
require 'openssl'

class Cryptiferous
  
  class << self
    
    def directory_hash(root_path)
      root_path += '/' unless root_path.match(/\/$/)
      directory = {}
      Find.find(root_path) do |path|
        if FileTest.directory?(path)
          next
        else
          short_path = path.gsub(root_path,'')
          directory[hash_file(path).to_s] = short_path
        end
      end
      return directory
    end
    
    def hash_file(path)
      sha1 = OpenSSL::Digest::SHA1.new
      File.open(path) do |file|
        buffer = ''
        while not file.eof
          file.read(512, buffer)
          sha1.update(buffer)
        end
      end
      return sha1
    end
  end
end

require File.expand_path('../lib/cloud_encrypted_sync/version', __FILE__)

Gem::Specification.new do |s|
  s.name = "cloud_encrypted_sync"
  s.version = CloudEncryptedSync::VERSION
  s.platform = Gem::Platform::RUBY
  s.authors = ["Jonathan S. Garvin"]
  s.email = ["jon@5valleys.com"]
  s.homepage = "https://github.com/jsgarvin/cloud_encrypted_sync"
  s.summary = %q{Encrypted sync of folder contents to/from cloud storage.}
  s.description = %q{Encrypted sync of folder contents to/from cloud storage with user controlled encryption keys.}

  s.add_dependency('activesupport')

  s.add_development_dependency('mocha')
  s.add_development_dependency('simplecov')
  s.add_development_dependency('fakefs')
  s.add_development_dependency('activesupport')

  s.files = `git ls-files`.split("\n")
  s.test_files = `git ls-files -- test/*`.split("\n")
  s.executables = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end

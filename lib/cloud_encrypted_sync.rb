require 'active_support/core_ext/string'
require 'digest'
require 'fileutils'
require 'find'
require 'openssl'
require 'singleton'
require 'yaml'

require File.expand_path('../cloud_encrypted_sync/adapter_liaison', __FILE__)
require File.expand_path('../cloud_encrypted_sync/adapter_template', __FILE__)
require File.expand_path('../cloud_encrypted_sync/configuration', __FILE__)
require File.expand_path('../cloud_encrypted_sync/cryptographer', __FILE__)
require File.expand_path('../cloud_encrypted_sync/dummy_adapter', __FILE__)
require File.expand_path('../cloud_encrypted_sync/errors', __FILE__)
require File.expand_path('../cloud_encrypted_sync/index', __FILE__)
require File.expand_path('../cloud_encrypted_sync/progress_meter', __FILE__)
require File.expand_path('../cloud_encrypted_sync/synchronizer', __FILE__)
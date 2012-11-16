module CloudEncryptedSync
  module Errors
    class RegistrationError < RuntimeError; end
    class IncompleteConfigurationError < RuntimeError; end
    class NoSuchKey < RuntimeError; end
    class TemplateMethodCalled < RuntimeError; end
  end
end
require 'openssl'

module Ripple
  module Contrib
    # Generic error class for Config
    class ConfigError < StandardError; end

    # Handles the configuration information for the Encryptor.
    #
    # Example usage:
    #     Ripple::Contrib::Config.defaults
    #     Ripple::Contrib::Config.new(:iv => "SOMEIV").to_h
    class Config
      # Initializes the config from our yml file.
      # @param [Hash] options to override those in the yml file
      def initialize(options={})
        @config = YAML.load_file(Config.path)[ENV['RACK_ENV']]
        @config.merge! options
      end

      # Return the options in the hash expected by Encryptor.
      def to_h
        @config
      end

      # Return either the default initialization vector, or create a new one.
      def activate
        @config['iv'] ||= OpenSSL::Random.random_bytes(16)
      end

      def self.path
        file = File.expand_path(File.join('..','..','..','config','encryption.yml'),__FILE__)
        if !File.exists? file
          raise Ripple::Contrib::ConfigError, <<MISSINGFILE
The file "config/encryption.yml" is missing or incorrect. You will
need to create this file and populate it with a valid cipher,
initialization vector and secret key.  An example is provided in 
"config/encryption.yml.example".
MISSINGFILE
        end
        file
      end
    end
  end
end

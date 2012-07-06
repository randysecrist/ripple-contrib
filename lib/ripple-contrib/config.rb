require 'openssl'

module Ripple
  module Contrib
    # Handles the configuration information for the Encryptor.
    #
    # Example usage:
    #     Ripple::Contrib::Config.defaults
    #     Ripple::Contrib::Config.new(:iv => "SOMEIV").to_h
    class Config
      # Initializes the config from our yml file.
      # @param [Hash] options to override those in the yml file
      def initialize(options={})
        @config = YAML.load_file("config/encryption.yml")[ENV['RACK_ENV']]
        @config.merge! options
        # if the environment doesn't provide one,
        # then we create an initialization vector
        @config['iv'] ||= OpenSSL::Random.random_bytes 16
      end

      # Convenience method for code readability.
      def self.defaults
        self.new().to_h
      end

      # Return the options in the hash expected by Encryptor.
      def to_h
        @config
      end
    end
  end
end

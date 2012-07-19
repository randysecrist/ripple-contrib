module Ripple
  module Contrib
    # Generic error class for Encryptor
    class EncryptedJsonDocumentError < StandardError; end

    # Interprets a encapsulation in JSON for encrypted Ripple documents.
    #
    # Example usage:
    #     Ripple::Contrib::JsonDocument.new(@document).encrypt
    class EncryptedJsonDocument
      # Creates an object that is prepared to decrypt its contents.
      # @param [String] data json string that was stored in Riak
      def initialize(config, data)
        @config = config.to_h
        @json = JSON.parse data

        raise(EncryptedJsonDocumentError, "Missing 'iv' for decryption") unless @json['iv']
        iv = Base64.decode64 @json['iv']
        @config.merge('iv' => iv)

        @decryptor = Ripple::Contrib::Encryptor.new @config
      end

      # Returns the original data from the stored encrypted format
      def decrypt
        JSON.load @decryptor.decrypt Base64.decode64 @json['data']
      end
    end
  end
end

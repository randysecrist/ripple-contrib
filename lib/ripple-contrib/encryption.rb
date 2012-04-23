require 'openssl'
require 'ripple'

module Ripple

  module Contrib

    # When mixed into a Ripple::Document class, this will encrypt the
    # serialized form before it is stored in Riak.  You must register
    # a serializer that will perform the encryption.
    # @see EncryptedSerializer
    module Encryption
      extend ActiveSupport::Concern

      @@is_activated = false

      included do
        @@encrypted_content_type = self.encrypted_content_type = 'application/x-json-encrypted'
      end

      module ClassMethods
        # @return [String] the content type to be used to indicate the
        #     proper encryption scheme. Defaults to 'application/x-json-encrypted'
        attr_accessor :encrypted_content_type
      end

      # Overrides the internal method to set the content-type to be
      # encrypted.
      def update_robject
        super
        if @@is_activated
          robject.content_type = @@encrypted_content_type
        end
      end

      def self.activate
        encryptor = nil
        begin
          unless Riak::Serializers['application/x-json-encrypted']
            config = YAML.load_file("config/encryption.yml")[ENV['RACK_ENV']]
            encryptor = Ripple::Contrib::EncryptedSerializer.new(OpenSSL::Cipher.new(config['cipher']))
            encryptor.key = config['key'] if config['key']
            encryptor.iv = config['iv'] if config['iv']
            Riak::Serializers['application/x-json-encrypted'] = encryptor
            @@is_activated = true
          end
        rescue Exception => e
          handle_invalid_encryption_config(e.message, e.backtrace)
        end
        encryptor
      end

      def self.activated
        @@is_activated
      end

    end

    # Implements the {Riak::Serializer} API for the purpose of
    # encrypting/decrypting Ripple documents.
    #
    # Example usage:
    #     ::Riak::Serializers['application/x-json-encrypted'] = EncryptedSerializer.new(OpenSSL::Cipher.new("AES-256"))
    #     class MyDocument
    #       include Ripple::Document
    #       include Riak::Encryption
    #     end
    #
    # @see Encryption
    class EncryptedSerializer
      # @return [String] The Content-Type of the internal format,
      #      generally "application/json"
      attr_accessor :content_type

      # @return [OpenSSL::Cipher, OpenSSL::PKey::*] the cipher used to encrypt the object
      attr_accessor :cipher

      # Cipher-specific settings
      # @see OpenSSL::Cipher
      attr_accessor :key, :iv, :key_length, :padding

      # Creates a serializer using the provided cipher and internal
      # content type. Be sure to set the {#key}, {#iv}, {#key_length},
      # {#padding} as appropriate for the cipher before attempting
      # (de-)serialization.
      # @param [OpenSSL::Cipher] cipher the desired
      #     encryption/decryption algorithm
      # @param [String] content_type the Content-Type of the
      #     unencrypted contents
      def initialize(cipher, content_type='application/json')
        @cipher, @content_type = cipher, content_type
      end

      # Serializes and encrypts the Ruby object using the assigned
      # cipher and Content-Type.
      # @param [Object] object the Ruby object to serialize/encrypt
      # @return [String] the serialized, encrypted form of the object
      def dump(object)
        internal = ::Riak::Serializers.serialize(content_type, object)
        encrypt(internal)
      end

      # Decrypts and deserializes the blob using the assigned cipher
      # and Content-Type.
      # @param [String] blob the original content from Riak
      # @return [Object] the decrypted and deserialized object
      def load(blob)
        internal = decrypt(blob)
        ::Riak::Serializers.deserialize(content_type, internal)
      end

      private

      # generates a new iv each call unless a static (less secure)
      # iv is used.
      def encrypt(object)
        result = ''
        if cipher.respond_to?(:iv=) and @iv == nil
          iv = OpenSSL::Random.random_bytes(cipher.iv_len)
          cipher.iv = iv
          result << Ripple::Contrib::VERSION << iv
        end

        if cipher.respond_to?(:public_encrypt)
          result << cipher.public_encrypt(object)
        else
          cipher_setup :encrypt
          result << cipher.update(object) << cipher.final
          cipher.reset
        end
        result
      end

      def decrypt(object)
        cipher_text = object

        if cipher.respond_to?(:iv=) and @iv == nil
          version = object.slice(0, Ripple::Contrib::VERSION.length)
          cipher.iv = object.slice(Ripple::Contrib::VERSION.length, cipher.iv_len)
          cipher_text = object.slice(Ripple::Contrib::VERSION.length + cipher.iv_len, object.length)
        end

        if cipher.respond_to?(:private_decrypt)
          cipher.private_decrypt(cipher_text)
        else
          cipher_setup :decrypt
          result = cipher.update(cipher_text) << cipher.final
          cipher.reset
          result
        end
      end

      def cipher_setup(mode)
        cipher.send mode
        cipher.key        = key        if key
        cipher.iv         = iv         if iv
        cipher.key_length = key_length if key_length
        cipher.padding    = padding    if padding
      end
    end

  end

end

def handle_invalid_encryption_config(msg, trace)
  puts <<eos

    The file "config/encryption.yml" is missing or incorrect. You will
    need to create this file and populate it with a valid cipher,
    initialization vector and secret key.

    An example is provided in "config/encryption.yml.example".
eos

  puts "Error Message: " + msg
  puts "Error Trace:"
  trace.each do |line|
    puts line
  end

  exit 1
end

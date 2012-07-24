require 'helper'

class EncryptedDocument
  include Ripple::Document
  include Ripple::Contrib::Encryption

  property :name, String
end

class TestEncryption < Test::Unit::TestCase
  context "Ripple::Contrib::Encryption" do
    should "set the default encrypted content type on the document" do
      assert_equal EncryptedDocument.encrypted_content_type, "application/x-json-encrypted"
    end
  end

  context "Ripple::Contrib::EncryptedSerializer" do
    should "be activated in test/helper.rb" do
      assert Ripple::Contrib::Encryption.activated
    end

    context "using AES symmetric encryption" do
      setup do
        @encryptor = Ripple::Contrib::EncryptedSerializer.new(OpenSSL::Cipher.new("AES-256-CBC"), 'application/x-json-encrypted', ENV['ENCRYPTION'])
        @encryptor.key = 'basho123456789101112basho_test12'
      end

      should "encrypt & decrypt using aes encryptor" do
        input = {"name" => "basho"}
        expected = YAML.dump(input)
        cipher_text = @encryptor.dump(input)
        assert cipher_text != input
        result = YAML.dump(@encryptor.load(cipher_text))
        assert_equal expected, result
      end
    end

  end
end

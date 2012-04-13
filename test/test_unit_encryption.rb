require 'test/unit'
require 'contest'

require 'support/ripple_test_server'
require 'ripple-contrib/encryption'

class EncryptedDocument
  include Ripple::Document
  include Ripple::Contrib::Encryption

  property :name, String
end

class NullCipher
  def public_encrypt(string); string; end
  def private_decrypt(string); string; end
end

class TestEncryption < Test::Unit::TestCase
  context "Ripple::Contrib::Encryption" do
    should "set the default encrypted content type on the document" do
      assert_equal EncryptedDocument.encrypted_content_type, "application/x-json-encrypted"
    end
  end

  context "Ripple::Contrib::EncryptedSerializer" do
    setup do
      @encryptor = Ripple::Contrib::EncryptedSerializer.new(NullCipher.new)
    end

    should "serialize using the internal content type" do
      expected = YAML.dump({"name" => "basho"})
      @encryptor.content_type = "application/yaml"
      assert_equal @encryptor.dump({"name" => "basho"}), expected
    end

    should "deserialize using the internal content type" do
      input = YAML.dump({"name" => "basho"})
      @encryptor.content_type = "application/yaml"
      assert_equal @encryptor.load(input), {"name" => "basho"}
    end

    context "using asymmetric encryption" do
      setup do
        @key = OpenSSL::PKey::RSA.new(File.read("test/support/fixtures/privkey.pem"), "basho")
        @encryptor = Ripple::Contrib::EncryptedSerializer.new(@key)
      end

      should "encrypt using the public key" do
        assert_equal @key.private_decrypt(@encryptor.dump({"name" => "basho"})), '{"name":"basho"}'
      end

      should "decrypt using the private key" do
        assert_equal @encryptor.load(@key.public_encrypt('{"name":"basho"}')), {"name" => "basho"}
      end
    end

    context "using DES symmetric encryption" do
      setup do
        @encryptor = Ripple::Contrib::EncryptedSerializer.new(OpenSSL::Cipher.new("DES3"))
        @encryptor.key = "basho12345678910818761057920"
      end

      should "encrypt & decrypt using des encryptor" do
        input = {"name" => "basho"}
        expected = YAML.dump(input)
        cipher_text = @encryptor.dump(input)
        assert cipher_text != input
        result = YAML.dump(@encryptor.load(cipher_text))
        assert_equal expected, result
      end
    end

    context "using AES symmetric encryption" do
      setup do
        @encryptor = Ripple::Contrib::EncryptedSerializer.new(OpenSSL::Cipher.new("AES-256-CBC"))
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

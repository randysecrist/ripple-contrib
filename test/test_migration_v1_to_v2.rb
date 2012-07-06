require 'helper'

class TestMigrationV1ToV2 < Test::Unit::TestCase
  context "Ripple::Contrib::Encryption" do
    should "set the default encrypted content type on the document" do
      assert_equal EncryptedDocument.encrypted_content_type, "application/x-json-encrypted"
    end
  end

  context "Ripple::Contrib::EncryptedSerializer" do
    setup do
      @encryptor = Ripple::Contrib::EncryptedSerializer.new(NullCipher.new)
      @encryptor.base64 = false
    end

    should "not be activated by default" do
      assert_equal false, Ripple::Contrib::Encryption.activated
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

    context "using base64 encoding" do
      setup do
        @encryptor = Ripple::Contrib::EncryptedSerializer.new(NullCipher.new)
        @encryptor.base64 = true
      end

      should "serialize to base64" do
        input = {"name" => "basho"}
        expected = Base64.encode64 YAML.dump(input)
        @encryptor.content_type = "application/yaml"
        assert_equal expected, @encryptor.dump(input)
      end

      should "deserialize from base64" do
        expected = {"name" => "basho"}
        input = Base64.encode64 YAML.dump(expected)
        @encryptor.content_type = "application/yaml"
        assert_equal expected, @encryptor.load(input)
      end
    end

  end
end

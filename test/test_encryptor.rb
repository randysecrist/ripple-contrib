require 'helper'

class TestEncryptor < Test::Unit::TestCase
  context "Ripple::Contrib::Encryptor" do
    setup do
      config     = Ripple::Contrib::Config.new ENV['ENCRYPTION']
      @encryptor = Ripple::Contrib::Encryptor.new config.to_h
      # example text
      @text      = "This is some nifty text."
      # this is the example text encrypted
      @blob      = "4\xD5\xE0F\fE\xBC/\xC8KDk_\v\xC5\x15\xB7\xD0\x02j\xB7\r\xB4'\x1Fz\xCE\x9B\xFC\x1FK?"
    end

    should "convert text to an encrypted blob" do
      assert_equal @blob, @encryptor.encrypt(@text), "Encryption failed."
    end

    should "convert encrypted blob to text" do
      assert_equal @text, @encryptor.decrypt(@blob), "Decryption failed."
    end
  end

  context "Ripple::Contrib::Encryptor with missing parameter" do
    should "raise an error if key is missing" do
      assert_raise Ripple::Contrib::EncryptorConfigError do
        Ripple::Contrib::Encryptor.new(:iv => 'iv', :cipher => 'AES-256-CBC')
      end
    end

    should "raise an error if iv is missing" do
      assert_raise Ripple::Contrib::EncryptorConfigError do
        Ripple::Contrib::Encryptor.new(:key => 'key', :cipher => 'AES-256-CBC')
      end
    end

    should "raise an error if cipher is missing" do
      assert_raise Ripple::Contrib::EncryptorConfigError do
        Ripple::Contrib::Encryptor.new(:key => 'key', :iv => 'iv')
      end
    end
  end
end

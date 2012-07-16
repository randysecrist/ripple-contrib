require 'helper'

class TestJsonDocument < Test::Unit::TestCase
  context "Ripple::Contrib::JsonDocument" do
    setup do
      # get some encryption going
      config    = Ripple::Contrib::Config.defaults
      encryptor = Ripple::Contrib::Encryptor.new config

      # this is the data package that we want
      @document = {'some' => 'data goes here'}

      # this is how we want that data package to actually be stored
      encrypted_value = encryptor.encrypt JSON.dump @document
      @encrypted_document = JSON.dump({:version => Ripple::Contrib::VERSION, :iv => Base64.encode64(config['iv']), :data => Base64.encode64(encrypted_value)})
    end

    should "convert a document to our desired JSON format" do
      assert_equal @encrypted_document, Ripple::Contrib::JsonDocument.new(@document).encrypt, 'Did not get the JSON format expected.'
    end

    should "interpret our JSON format into a document" do
      assert_equal @document, Ripple::Contrib::EncryptedJsonDocument.new(@encrypted_document).decrypt, 'Did not get the JSON format expected.'
    end
  end

  context "Ripple::Contrib::JsonDocument with no initialization vector" do
    setup do
      # this is the data package that we want
      @document = {'some' => 'data goes here'}

      # rig a JsonDocument without an iv
      ENV['RACK_ENV'] = 'test-without-iv'
      @json_document = Ripple::Contrib::JsonDocument.new(@document)
      ENV['RACK_ENV'] = 'test'
    end

    should "convert a document to our desired JSON format and back again" do
      @encrypted_document = @json_document.encrypt
      assert_equal @document, Ripple::Contrib::EncryptedJsonDocument.new(@encrypted_document).decrypt, 'Did not get the JSON format expected.'
    end
  end
end

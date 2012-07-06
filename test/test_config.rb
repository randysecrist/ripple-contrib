require 'helper'

class TestConfig < Test::Unit::TestCase
  context "Ripple::Contrib::Config" do
    should "override the defaults with new values" do
      config = Ripple::Contrib::Config.new('key' => 'somekey')
      assert_equal 'somekey', config.to_h['key']
      assert_equal 'AES-256-CBC', config.to_h['cipher']
    end
  end
end

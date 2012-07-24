require 'helper'

class TestConfig < Test::Unit::TestCase
  context "Ripple::Contrib::Config" do
    should "raise heck if the config file isn't found" do
      assert_raise Ripple::Contrib::ConfigError do
        config = Ripple::Contrib::Config.new('nowhere')
      end
    end
  end
end

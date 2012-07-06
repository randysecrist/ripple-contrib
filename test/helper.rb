$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'test/unit'
require 'contest'

require 'support/ripple_test_server'
require 'ripple-contrib'

#require 'app/app'
#require 'lib/command'
require 'test/support/ripple_test_server'
Ripple::TestServer.setup
def run_at_exit
  at_exit do
#    if $! || Test::Unit.run?
      Ripple::TestServer.destroy
#    end
  end
end
run_at_exit

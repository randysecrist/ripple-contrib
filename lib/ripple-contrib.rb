require 'rake'

module Ripple
  module Contrib
  end
end

# Include all of the support files.
FileList[File.expand_path('../ripple-contrib/*.rb',__FILE__)].each{|f| require f}

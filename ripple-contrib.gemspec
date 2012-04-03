# -*- encoding: utf-8 -*-
require File.expand_path('../lib/ripple-contrib/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Randy Secrist"]
  gem.email         = ["randy.secrist@gmail.com"]
  gem.description   = %q{A collection of handy mixins used with riak and ripple.}
  gem.summary       = %q{A collection of handy mixins used with riak and ripple.}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "ripple-contrib"
  gem.require_paths = ["lib"]
  gem.version       = Ripple::Contrib::VERSION

  gem.add_dependency 'riak-client'
  gem.add_dependency 'ripple'

  # Test Dependencies
  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'contest'
end

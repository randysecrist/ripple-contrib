# Ripple::Contrib

The ripple-contrib gem is a library of additional model behaviors that
are not currently found within (but may eventually become part of) the
core [riak-ruby](https://github.com/basho/riak-ruby-client) or [ripple](https://github.com/seancribbs/ripple) distributions.

Generally speaking, the behaviors found within support use cases that
have more edge cases, but should still strive to apply to a common base.

## Installation

Add this line to your application's Gemfile:

    gem 'ripple-contrib'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install ripple-contrib

## Usage

### Encryption

Be sure to refer to the [config/encryption.yml.example](https://github.com/randysecrist/ripple-contrib/blob/master/config/encryption.yml.example) before requiring
this gem.  Once that is done, simply [add the ruby mixin](https://github.com/randysecrist/ripple-contrib/blob/master/test/test_unit_encryption.rb#L9) to a model class.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

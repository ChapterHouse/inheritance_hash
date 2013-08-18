# InheritanceHash

A hash that can inherit entries from other normal hashes or other inheritance hashes.
Originally created for class level attributes, InheritanceHash is designed for maintaining hashes in an inheritable fashion such that changes in the parent can be reflected in the children but not vice versa.


## Installation

Add this line to your application's Gemfile:

    gem 'inheritance_hash'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install inheritance_hash

## Usage

  Use it just like a normal hash only call InheritanceHash.new
  To inherit values from another hash use: ihash.inherit_from(other_hash)
  To prevent inheriting a specific value use: ihash.dont_inherit(key)

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

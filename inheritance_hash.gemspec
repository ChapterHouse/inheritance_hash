# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'inheritance_hash/version'

Gem::Specification.new do |spec|
  spec.name          = 'inheritance_hash'
  spec.version       = InheritanceHash::VERSION
  spec.authors       = ['Frank Hall']
  spec.email         = ['ChapterHouse.Dune@gmail.com']
  spec.description   = %q{A hash that can inherit entries from other normal hashes or other inheritance hashes.}
  spec.summary       = %q{Originally created for class level attributes, InheritanceHash is designed for maintaining hashes in an inheritable fashion such that changes in the parent can be reflected in the children but not vice versa.}
  spec.homepage      = 'http://chapterhouse.github.io/inheritance_hash'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rdoc'

end

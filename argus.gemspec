# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'argus/version'

Gem::Specification.new do |spec|
  spec.name          = "argus-builder"
  spec.version       = Argus::VERSION
  spec.authors       = ['Richard Lister']
  spec.email         = ['rlister+gh@gmail.com']

  spec.summary       = %q{Docker image builder for AWS Elastic Container Registry.}
  spec.homepage      = 'https://github.com/rlister/argus'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = %w[lib]

  spec.add_development_dependency "bundler", "~> 1.11"
  spec.add_development_dependency "rake", "~> 10.0"

  spec.add_dependency('aws-sdk', '>= 2.2.20')
  spec.add_dependency('shoryuken')
  spec.add_dependency('docker-api')
end
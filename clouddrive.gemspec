# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'clouddrive/version'

Gem::Specification.new do |spec|
  spec.name          = "clouddrive"
  spec.version       = CloudDrive::VERSION
  spec.authors       = ["Alex Phillips"]
  spec.email         = ["ahp118@gmail.com"]

  spec.summary       = %q{Cloud Drive for Ruby}
  spec.description   = %q{Ruby SDK and command line application for Amazon's Cloud Drive}
  spec.homepage      = "https://github.com/alex-phillips/clouddrive"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  # if spec.respond_to?(:metadata)
  #   spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  # else
  #   raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  # end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) } + Dir['lib/**/*.rb']
  spec.bindir        = "bin"
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.9"
  spec.add_development_dependency "rake", "~> 10.0"

  spec.add_runtime_dependency "rest-client", "~> 1.8"
  spec.add_runtime_dependency "clamp", "~> 1.0"
  spec.add_runtime_dependency "sqlite3", "~> 1.3"
  spec.add_runtime_dependency "colorize", "~> 0.7"
  spec.add_runtime_dependency "sequel", "~> 4.27"
end

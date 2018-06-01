# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'sentry_slack_bot/version'

Gem::Specification.new do |spec|
  spec.name          = "sentry_slack_bot"
  spec.version       = SentrySlackBot::VERSION
  spec.authors       = ["Jon Bauer"]
  spec.email         = ["bauerjon@hotmail.com"]

  spec.summary       = "No sentry slack notification left behind."
  spec.description   = "Notifies slack room with sentry reports around stale assignments, and works in tandem with https://sentry.io/integrations/slack/ to notify people in a thread when people haven't acknowledged issues."
  spec.homepage      = "https://github.com/bauerjon/sentry_slack_bot/"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.required_ruby_version = '~> 2.1.0'

  spec.add_dependency "activesupport"
  spec.add_dependency "httparty"

  spec.add_development_dependency "bundler", "~> 1.12"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "webmock"
end

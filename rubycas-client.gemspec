lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "casclient/version"

Gem::Specification.new do |s|
  s.name = "rubycas-client"
  s.version = CASClient::VERSION
  s.authors = ["Matt Zukowski", "Matt Walker", "Matt Campbell"]

  s.summary = "Client library for the Central Authentication Service (CAS) protocol."
  s.homepage = "https://github.com/rubycas/rubycas-client"
  s.licenses = ["MIT"]

  # Prevent pushing this gem to RubyGems.org.
  s.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  s.files = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  s.require_paths = ["lib"]

  s.add_runtime_dependency 'activesupport', '>= 0'
  s.add_runtime_dependency 'dalli', '>= 2.0'
  s.add_runtime_dependency 'redis', '>= 4.1'
  s.add_runtime_dependency 'dice_bag', '>= 0.9', '< 2.0'

  s.add_development_dependency 'json', '>= 0'
  s.add_development_dependency 'rspec', '>= 0'
  s.add_development_dependency 'bundler', '>= 1.0'
  s.add_development_dependency 'jeweler', '>= 0'
  s.add_development_dependency 'actionpack', '>= 0'
  s.add_development_dependency 'activerecord', '>= 0'
  s.add_development_dependency 'rake', '>= 0'
  s.add_development_dependency 'simplecov', '>= 0'
  s.add_development_dependency 'guard', '>= 0'
  s.add_development_dependency 'guard-rspec', '>= 0'
  s.add_development_dependency 'database_cleaner', '>= 0'
  s.add_development_dependency 'sqlite3', '>= 0'
end

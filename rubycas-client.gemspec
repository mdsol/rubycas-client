# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "rubycas-client"
  s.version = "2.2.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Matt Zukowski", "Matt Walker"]
  s.date = "2008-11-18"
  s.description = "Client library for the Central Authentication Service (CAS) protocol."
  s.email = "matt at roughest dot net"
  s.extra_rdoc_files = ["CHANGELOG.txt", "History.txt", "LICENSE.txt", "Manifest.txt", "README.rdoc"]
  s.files = ["CHANGELOG.txt", "History.txt", "LICENSE.txt", "Manifest.txt", "README.rdoc", "Rakefile", "init.rb", "lib/casclient.rb", "lib/casclient/client.rb", "lib/casclient/frameworks/rails/cas_proxy_callback_controller.rb", "lib/casclient/frameworks/rails/filter.rb", "lib/casclient/frameworks/merb/strategy.rb", "lib/casclient/responses.rb", "lib/casclient/tickets.rb", "lib/casclient/version.rb", "lib/rubycas-client.rb", "setup.rb"]
  s.homepage = "http://rubycas-client.rubyforge.org"
  s.rdoc_options = ["--main", "README.txt"]
  s.require_paths = ["lib"]
  s.rubyforge_project = "rubycas-client"
  s.rubygems_version = "1.8.25"
  s.summary = "Client library for the Central Authentication Service (CAS) protocol."

  if s.respond_to? :specification_version then
    s.specification_version = 2

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<activesupport>, [">= 0"])
      s.add_development_dependency(%q<hoe>, [">= 1.7.0"])
    else
      s.add_dependency(%q<activesupport>, [">= 0"])
      s.add_dependency(%q<hoe>, [">= 1.7.0"])
    end
  else
    s.add_dependency(%q<activesupport>, [">= 0"])
    s.add_dependency(%q<hoe>, [">= 1.7.0"])
  end
end

source 'https://rubygems.org'

group :development do
  gem 'actionpack', '~> 5.2', require: 'action_pack'
  gem 'database_cleaner', '~> 0.7'
  gem 'jeweler', '~> 1.8'
  gem 'json', '>= 1.8.5'
  gem 'rake', '~> 0.9'
  gem 'rspec', '~> 2.8'
  gem 'simplecov', '~> 0.5', require: false

  platforms :ruby do
    gem 'sqlite3', '~> 1.3'
  end

  platforms :jruby do
    gem 'activerecord-jdbcsqlite3-adapter'
    gem 'jruby-openssl'
  end
end

gem 'nokogiri', '~> 1.6'

gemspec


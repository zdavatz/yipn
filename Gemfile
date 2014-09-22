source "http://rubygems.org"
if /^2/.match(RUBY_VERSION)
  gem 'paypal'
elsif /^1\.8/.match(RUBY_VERSION)
  gem "mime-types", "~> 1.16"
  gem 'paypal', '2.0.0'
else
  ruby "1.9.3"
  gem 'paypal', '2.0.0'
end

gem 'activesupport'
gem 'rclconf', '1.0.0'
gem 'mail'

group :development, :test do
  gem "rake"
  gem 'flexmock'
  gem 'minitest', '>=5.0'
  gem 'simplecov', '~> 0.7.1'
  gem 'travis-lint'
end

group :test do
  gem 'rspec'
  gem 'minitest-should_syntax'
end

group :debugger do
if /^2/.match(RUBY_VERSION)
  gem 'pry-byebug'
elsif /^1\.8/.match(RUBY_VERSION)
else
  gem 'pry-debugger'
end
end

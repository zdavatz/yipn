source "http://rubygems.org"
if /^2/.match(RUBY_VERSION)
  ruby '2.1.2'
  gem 'dbi', :git => 'https://github.com/ngiger/ruby-dbi'
  gem 'syck'
else
  ruby "1.9.3"
  gem 'dbi', :git => 'https://github.com/ngiger/ruby-dbi'
end

gem 'paypal', '2.0.0'
gem 'mail' , '2.2.7'
gem 'money' # , '6.0.1'
gem 'rclconf', '1.0.0'

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
  gem 'watir'
  gem 'watir-webdriver'
  gem 'page-object'
end

group :debugger do
if /^2/.match(RUBY_VERSION)
  gem 'pry-byebug'
else
  gem 'pry-debugger'
end
end

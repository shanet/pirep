source 'https://rubygems.org'
git_source(:github) {|repo| "https://github.com/#{repo}.git"}

ruby '3.0.4'

# Core Rails gems
gem 'rails', '7.0.4'

gem 'bootsnap', '>= 1.4.2', require: false
gem 'dartsass-rails', '~> 0.4.0'
gem 'importmap-rails'
gem 'jbuilder', '~> 2.7'
gem 'pg', '>= 0.18', '< 2.0'
gem 'puma', '~> 4.1'
gem 'sprockets-rails'

# Third party gems
gem 'activerecord-cte'
gem 'amazing_print'
gem 'brakeman'
gem 'bundler-audit'
gem 'devise'
gem 'diffy'
gem 'erb_lint', '>= 0.0.35'
gem 'faraday'
gem 'good_job'
gem 'kramdown'
gem 'maxmind-geoip2'
gem 'paper_trail'
gem 'pundit'
gem 'rack-attack'
gem 'rubyzip'
gem 'sentry-rails'
gem 'sentry-ruby'

group :development, :test do
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
  gem 'rubocop'
  gem 'rubocop-rails'
end

group :development do
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'listen', '~> 3.2'
end

group :test do
  gem 'capybara', '>= 2.15'
  gem 'factory_bot_rails'
  gem 'selenium-webdriver', '>= 4.3.0'
  gem 'webdrivers'
end

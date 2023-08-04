source 'https://rubygems.org'
git_source(:github) {|repo| "https://github.com/#{repo}.git"}

ruby '3.2.2'

# Core Rails gems
gem 'rails', '7.0.6'

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
gem 'aws-sdk-ecs'
gem 'aws-sdk-s3'
gem 'brakeman'
gem 'bundler-audit'
gem 'devise'
gem 'diffy'
gem 'erb_lint', '>= 0.0.35'
gem 'faraday'
gem 'foreman'
gem 'good_job'
gem 'image_processing'
gem 'jit_preloader'
gem 'kramdown'
gem 'maxmind-geoip2'
gem 'paper_trail'
gem 'pundit'
gem 'rack-attack'
gem 'rubyzip'
gem 'sentry-rails'
gem 'sentry-ruby'
gem 'skylight'
gem 'terminal-table'
gem 'user_agent_parser'

group :development, :test do
  gem 'aws-sdk-codedeploy'
  gem 'aws-sdk-codepipeline'
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
  gem 'cli-ui'
  gem 'rubocop'
  gem 'rubocop-capybara'
  gem 'rubocop-factory_bot'
  gem 'rubocop-rails'
  gem 'webmock'
end

group :development do
  # This can be updated when https://github.com/BetterErrors/better_errors/issues/516 is resolved
  gem 'better_errors', '2.9.1'
  gem 'binding_of_caller'
  gem 'listen', '~> 3.2'
end

group :test do
  gem 'capybara', '>= 2.15'
  gem 'factory_bot_rails'
  gem 'selenium-webdriver', '>= 4.11'
end

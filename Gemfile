source 'https://rubygems.org'
git_source(:github) {|repo| "https://github.com/#{repo}.git"}

ruby '3.0.3'

# Core Rails gems
gem 'rails', '6.0.4.1'

gem 'bootsnap', '>= 1.4.2', require: false
gem 'jbuilder', '~> 2.7'
gem 'pg', '>= 0.18', '< 2.0'
gem 'puma', '~> 4.1'
gem 'sass-rails', '>= 6'
gem 'webpacker', '~> 4.0'

# Use Active Storage variant
# gem 'image_processing', '~> 1.2'

# Third party gems
gem 'amazing_print'
gem 'bootstrap'
gem 'brakeman'
gem 'bundler-audit'
gem 'erb_lint', '>= 0.0.35'
gem 'faraday'
gem 'font-awesome-sass'
gem 'rubocop'
gem 'rubocop-rails'
gem 'rubyzip'

group :development, :test do
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
end

group :development do
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'listen', '~> 3.2'
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
end

group :test do
  gem 'capybara', '>= 2.15'
  gem 'factory_bot_rails'
  gem 'selenium-webdriver'
  gem 'webdrivers'
end

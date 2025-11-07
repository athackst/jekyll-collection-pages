# frozen_string_literal: true

source 'https://rubygems.org'
gemspec

gem 'jekyll', ENV['JEKYLL_VERSION'] if ENV['JEKYLL_VERSION']

gem 'webrick', '~> 1.8'

group :jekyll_plugins do
  gem 'jekyll-feed'
  gem 'jekyll-paginate'
  gem 'jekyll-redirect-from'
  gem 'jekyll-relative-links'
  gem 'jekyll-sitemap'
  gem 'jekyll-theme-profile' # needed for themeing
end

group :development do
  gem 'dotenv'
  gem 'html-proofer'
  gem 'rubocop'
end

# Required in Ruby 3.4+ when Jekyll < 4.4
gem 'base64'
gem 'bigdecimal'
gem 'csv'
gem 'logger'

# Required in Ruby 3.3.4 when Jekyll == 3.10
gem 'kramdown-parser-gfm'

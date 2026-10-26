# frozen_string_literal: true

source "https://rubygems.org"

gemspec

gem "rake", "~> 13.0"
gem "rspec", "~> 3.0"
gem "rubocop", "~> 1.21"
gem "rubocop-performance", "~> 1.0"

# unitsml 0.4.x ships a unitsdb artifact that crashes Bundler 4's
# setup_manpath glob on Windows (Errno::EINVAL on **/*.yaml); 0.5+
# vendored unitsdb as its own gem
gem "unitsml", ">= 0.5.1"

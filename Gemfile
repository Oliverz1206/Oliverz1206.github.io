# frozen_string_literal: true

source "https://rubygems.org"

gem "jekyll-theme-chirpy", "~> 7.3", ">= 7.3.1"

gem "html-proofer", "~> 5.0", group: :test

platforms :windows, :jruby do
  gem "tzinfo", ">= 1", "< 3"
  gem "tzinfo-data"
end

group :jekyll_plugins do
  gem "jekyll-archives", "~> 2.2"
  gem "jekyll-paginate-v2", "~> 3.0"
end

gem "wdm", "~> 0.2.0", :platforms => [:windows]

# 运行/服务用到的运行时库 —— Ruby 3.5 起不再默认内置，手动声明可消警告
gem "webrick", "~> 1.8"  # jekyll serve 用
gem "logger",  "~> 1.6"  # 消除 logger 将不再默认内置的警告
gem "fiddle",  "~> 1.1"  # 消除 fiddle/import 将不再默认内置的警告

require 'pathname'

source 'http://rubygems.org'

gemspec

SOURCE        = ENV.fetch('SOURCE', :git).to_sym
REPO_POSTFIX  = SOURCE == :path ? ''                                : '.git'
DATAMAPPER    = SOURCE == :path ? Pathname(__FILE__).dirname.parent : 'http://github.com/datamapper'
DM_VERSION    = '~> 1.2.0'
MONGO_VERSION = '~> 1.4.0'

group :runtime do

  # MongoDB driver
  gem 'dm-core', DM_VERSION

  plugins = ENV['PLUGINS'] || ENV['PLUGIN']
  plugins = plugins.to_s.tr(',', ' ').split.push('dm-migrations').push('dm-aggregates').uniq

  plugins.each do |plugin|
    gem plugin, DM_VERSION
  end
end

platforms :mri_18 do
  group :quality do
    gem 'rcov',      '~> 0.9.9'
    gem 'yard',      '~> 0.6'
    gem 'yardstick', '~> 0.2'
  end
end

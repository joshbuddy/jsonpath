require 'simplecov'
SimpleCov.start do
  add_filter '/test/'
end

require 'bundler'
Bundler::GemHelper.install_tasks

task :test do
  $LOAD_PATH << 'lib'
  Dir['./test/**/test_*.rb'].each { |test| require test }
end

task default: :test

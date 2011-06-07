require 'bundler'
Bundler::GemHelper.install_tasks

require 'rake/rdoctask'
desc "Generate documentation"
Rake::RDocTask.new do |rd|
  rd.main = "README.rdoc"
  rd.rdoc_files.include("README.rdoc", "lib/**/*.rb")
  rd.rdoc_dir = 'rdoc'
end

task :test do
  $: << 'lib'
  require 'minitest/autorun'
  require 'phocus'
  require 'jsonpath'
  Dir['./test/**/test_*.rb'].each { |test| require test }
end

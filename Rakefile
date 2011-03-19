require 'bundler'
Bundler::GemHelper.install_tasks

require 'rake/rdoctask'
desc "Generate documentation"
Rake::RDocTask.new do |rd|
  rd.main = "README.rdoc"
  rd.rdoc_files.include("README.rdoc", "lib/**/*.rb")
  rd.rdoc_dir = 'rdoc'
end

require 'rubygems'

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)

task :default => :spec
task :test => :spec
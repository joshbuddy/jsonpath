require 'rake/testtask'

#desc "Build it up"
#task :build do
#  sh "rex --independent -o lib/jsonpath/grammar.rex.rb lib/grammar/grammar.rex"
#  sh "racc -v -O parser.output -o lib/jsonpath/grammar.y.rb lib/grammar/grammar.y"
#end

begin
  require 'jeweler'
  Jeweler::Tasks.new do |s|
    s.name = "jsonpath"
    s.description = s.summary = "Ruby implementation of http://goessner.net/articles/JsonPath/"
    s.email = "joshbuddy@gmail.com"
    s.homepage = "http://github.com/joshbuddy/jsonpath"
    s.authors = ['Joshua Hull']
    s.files = `git ls-files`.split(/\n/)
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler not available. Install it with: sudo gem install technicalpickles-jeweler -s http://gems.github.com"
end

require 'rake/rdoctask'
desc "Generate documentation"
Rake::RDocTask.new do |rd|
  rd.main = "README.rdoc"
  rd.rdoc_files.include("README.rdoc", "lib/**/*.rb")
  rd.rdoc_dir = 'rdoc'
end

require 'rubygems'
require 'spec'
require 'spec/rake/spectask'

Spec::Rake::SpecTask.new do |t|
  t.ruby_opts = ['-rubygems']
  t.spec_opts ||= []
  t.spec_opts << "--options" << "spec/spec.opts"
  t.spec_files = FileList['spec/*.rb']
end

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/*_test.rb'
  test.verbose = true
end
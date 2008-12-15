require 'rubygems'
require 'hoe'
require 'spec'
require 'lib/jsonpath'
require 'spec/rake/spectask'

Hoe.new('jsonpath', JsonPath::VERSION) do |p|
  p.author = 'Joshua Hull'
  p.email = 'joshbuddy@gmail.com'
  p.summary = 'Ruby implementation of http://goessner.net/articles/JsonPath/'
  p.description = p.paragraphs_of('README.txt', 2..2).join("\n\n")
  p.changes = p.paragraphs_of('History.txt', 0..1).join("\n\n")
end

namespace(:spec) do

  task :all => [:jsont]

  Spec::Rake::SpecTask.new(:jsont) do |t|
    t.spec_opts ||= []
    t.spec_opts << "--options" << "spec/spec.opts"
    t.spec_files = FileList['spec/*.rb']
  end

end

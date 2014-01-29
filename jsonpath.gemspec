# -*- encoding: utf-8 -*-

require File.join(File.dirname(__FILE__), 'lib', 'jsonpath', 'version')

Gem::Specification.new do |s|
  s.name = 'jsonpath'
  s.version = JsonPath::VERSION
  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Joshua Hull"]
  s.summary = "Ruby implementation of http://goessner.net/articles/JsonPath/"
  s.description = "Ruby implementation of http://goessner.net/articles/JsonPath/."
  s.email = %q{joshbuddy@gmail.com}
  s.extra_rdoc_files = ['README.md']
  s.files = `git ls-files`.split("\n")
  s.homepage = %q{http://github.com/joshbuddy/jsonpath}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.7}
  s.test_files = `git ls-files`.split("\n").select{|f| f =~ /^spec/}
  s.rubyforge_project = 'jsonpath'
  s.executables = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.licenses    = ['MIT']

  # dependencies
  s.add_runtime_dependency 'multi_json'
  s.add_development_dependency 'code_stats'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'minitest', '~> 2.2.0'
  s.add_development_dependency 'phocus'
  s.add_development_dependency 'bundler'
end


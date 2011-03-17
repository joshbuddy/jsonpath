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
  s.extra_rdoc_files = ['README.rdoc']
  s.files = `git ls-files`.split("\n")
  s.homepage = %q{http://github.com/joshbuddy/jsonpath}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.7}
  s.test_files = `git ls-files`.split("\n").select{|f| f =~ /^spec/}
  s.rubyforge_project = 'jsonpath'

  # dependencies
  s.add_runtime_dependency 'json'
  s.add_development_dependency 'code_stats'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec', '< 2.0.0'
  s.add_development_dependency 'bundler',  '~> 1.0.0'

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end


# frozen_string_literal: true

require File.join(File.dirname(__FILE__), 'lib', 'jsonpath', 'version')

Gem::Specification.new do |s|
  s.name = 'jsonpath'
  s.version = JsonPath::VERSION
  if s.respond_to? :required_rubygems_version=
    s.required_rubygems_version =
      Gem::Requirement.new('>= 0')
  end
  s.authors = ['Joshua Hull', 'Gergely Brautigam']
  s.summary = 'Ruby implementation of http://goessner.net/articles/JsonPath/'
  s.description = 'Ruby implementation of http://goessner.net/articles/JsonPath/.'
  s.email = ['joshbuddy@gmail.com', 'skarlso777@gmail.com']
  s.extra_rdoc_files = ['README.md']
  s.files = `git ls-files`.split("\n")
  s.homepage = 'https://github.com/joshbuddy/jsonpath'
  s.rdoc_options = ['--charset=UTF-8']
  s.require_paths = ['lib']
  s.rubygems_version = '1.3.7'
  s.test_files = `git ls-files`.split("\n").select { |f| f =~ /^spec/ }
  s.rubyforge_project = 'jsonpath'
  s.executables = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  s.licenses    = ['MIT']

  # dependencies
  s.add_runtime_dependency 'multi_json'
  s.add_runtime_dependency 'to_regexp', '~> 0.2.1'
  s.add_development_dependency 'bundler'
  s.add_development_dependency 'code_stats'
  s.add_development_dependency 'minitest', '~> 2.2.0'
  s.add_development_dependency 'phocus'
  s.add_development_dependency 'rake'
end

require 'strscan'
require File.join('jsonpath', 'enumerable')
require File.join('jsonpath', 'version')

class JsonPath

  attr_reader :path

  def initialize(path)
    scanner = StringScanner.new(path)
    @path = []
    bracket_count = 0
    while not scanner.eos?
      if token = scanner.scan(/\$/)
        @path << token
      elsif token = scanner.scan(/@/)
        @path << token
      elsif token = scanner.scan(/[a-zA-Z]+/)
        @path << "['#{token}']"
      elsif token = scanner.scan(/'(.*?)'/)
        @path << "[#{token}]"
      elsif token = scanner.scan(/\[/)
        count = 1
        while !count.zero?
          if t = scanner.scan(/\[/)
            token << t
            count += 1
          elsif t = scanner.scan(/\]/)
            token << t
            count -= 1
          elsif t = scanner.scan(/[^\[\]]*/)
            token << t
          end
        end
        @path << token
      elsif token = scanner.scan(/\.\./)
        @path << token
      elsif scanner.scan(/\./)
      elsif token = scanner.scan(/\*/)
        @path << token
      elsif token = scanner.scan(/./)
        @path.last << token
      end
    end
  end

  def on(object)
    JsonPath::Enumerable.new(self, object)
  end

  def self.on(object, path)
    self.new(path).on(object)
  end

end

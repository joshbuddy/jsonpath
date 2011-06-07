require 'strscan'
require 'jsonpath/enumerable'
require 'jsonpath/version'

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
      elsif token = scanner.scan(/[a-zA-Z_]+/)
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
    enum_on(object).to_a
  end

  def enum_on(object)
    JsonPath::Enumerable.new(self, object)
  end

  def first_on(object)
    JsonPath::Enumerable.new(self, object).first
  end

  def self.on(object, path)
    self.new(path).on(object)
  end

end

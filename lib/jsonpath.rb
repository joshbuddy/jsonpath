require 'strscan'
require 'jsonpath/proxy'
require 'jsonpath/enumerable'
require 'jsonpath/version'

class JsonPath

  attr_reader :path

  def initialize(path, opts = nil)
    @opts = opts
    scanner = StringScanner.new(path)
    @path = []
    bracket_count = 0
    while not scanner.eos?
      if token = scanner.scan(/\$/)
        @path << token
      elsif token = scanner.scan(/@/)
        @path << token
      elsif token = scanner.scan(/[a-zA-Z0-9_]+/)
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
        nil
      elsif token = scanner.scan(/\*/)
        @path << token
      elsif token = scanner.scan(/[><=] \d+/)
        @path.last << token
      elsif token = scanner.scan(/./)
        @path.last << token
      end
    end
  end

  def on(object)
    enum_on(object).to_a
  end

  def first(object)
    enum_on(object).first
  end

  def enum_on(object)
    JsonPath::Enumerable.new(self, object, @opts)
  end

  def self.on(object, path, opts = nil)
    self.new(path, opts).on(object)
  end

  def self.for(obj)
    Proxy.new(obj)
  end
end

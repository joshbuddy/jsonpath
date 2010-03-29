require 'strscan'
require 'load_path_find'

$LOAD_PATH.add_current

require File.join('jsonpath', 'enumerable')

class JsonPath

  attr_reader :path

  def initialize(path)
    scanner = StringScanner.new(path)
    @path = []
    bracket_count = 0
    while not scanner.eos?
      if token = scanner.scan(/\$/)
        bracket_count == 0 && @path << token or @path[-1] << token
        bracket_count += token.count('[') - token.count(']')
      elsif token = scanner.scan(/@/)
        bracket_count == 0 && @path << token or @path[-1] << token
        bracket_count += token.count('[') - token.count(']')
      elsif token = scanner.scan(/[a-zA-Z]+/)
        @path << "['#{token}']"
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
        bracket_count == 0 && @path << token or @path[-1] << token
        bracket_count += token.count('[') - token.count(']')
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

end

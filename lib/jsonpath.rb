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
      token = scanner.scan_until(/($|\$|@|[a-zA-Z]+|\[.*?\]|\.\.|\.(?!\.))/)
      case token
      when '.'
        # do nothing
      when /^[a-zA-Z]+$/
        @path << "['#{token}']"
      else
        bracket_count == 0 && @path << token or @path[-1] += token
        bracket_count += token.count('[') - token.count(']')
      end
    end
  end

  def on(object)
    JsonPath::Enumerable.new(self, object)
  end

end

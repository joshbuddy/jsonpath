require 'strscan'

class JsonPath
  class Expression
    def initialize(expression, object = nil)
      scanner = StringScanner.new(expression)
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
      @object = object
    end
    
    def test?(node = @object)
      each(node) {|n| return true}
      false
    end
    
    def to_a(node = @object)
      store = []
      each(node) {|o| store << o}
      store
    end
    
    def map(node = @object)
      store = []
      each(node) {|o| store << (yield o)}
      store
    end
    
    def each(node = @object, pos = 0, options = {}, &blk)
      if pos == @path.size
        return blk.call(node)
      else
        case expr = @path[pos]
        when '*', '..'
          each(node, pos + 1, &blk) 
        when '$'
          each(node, pos + 1, &blk) if node == @object
        when '@'
          each(node, pos + 1, &blk)
        when /^\[(.*)\]$/
          expr[1,expr.size - 2].split(',').each do |sub_path|
            case sub_path[0]
            when ?', ?"
              if node.is_a?(Hash)
                key = sub_path[1,sub_path.size - 2]
                each(node[key], pos + 1, &blk) if node.key?(key) 
              end
            when ??
              (node.is_a?(Hash) ? node.keys : (0..node.size)).each do |e|
                ::JsonPath.path(sub_path[2,sub_path.size - 3]) do |jp|
                  @obj = node[e]
                  begin
                    each(node[e], pos + 1, &blk) if jp.test?(node[e])
                  rescue
                    # ignore ..
                  end
                end
              end
            else
              if node.is_a?(Array)
                @obj = node
                array_args = sub_path.gsub('@','@obj').split(':')
                start_idx = (array_args[0] && eval(array_args[0]) || 0) % node.size
                end_idx = (array_args[1] && eval(array_args[1]) || (sub_path.count(':') == 0 ? start_idx : -1)) % node.size
                step = array_args[2] && eval(array_args[2]) || 1
                (start_idx..end_idx).step(step) {|i| each(node[i], pos + 1, &blk)}
              end
            end
          end
        else
          blk.call(node) if pos == (@path.size - 1) && eval("node #{@path[pos]}")
        end
        
        if pos > 0 && @path[pos-1] == '..'
          case node
          when Hash
            node.values.each {|n| each(n, pos, &blk) }
          when Array
            node.each {|n| each(n, pos, &blk) }
          end
        end
      end
    end
  end
end
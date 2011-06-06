class JsonPath
  class Enumerable
    include ::Enumerable

    def initialize(path, object)
      @path, @object = path.path, object
    end

    def each(node = @object, pos = 0, &blk)
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
                subenum = ::JsonPath.new(sub_path[2,sub_path.size - 3]).on(node[e])
                each(node[e], pos + 1, &blk) if subenum.any?{|n| true}
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
          blk.call(node) if pos == (@path.size - 1) && node && eval("node #{@path[pos]}")
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

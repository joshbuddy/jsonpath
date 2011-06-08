class JsonPath
  class Enumerable
    include ::Enumerable

    def initialize(path, object, options = nil)
      @path, @object, @options = path.path, object, options
    end

    def each(node = @object, pos = 0, &blk)
      return blk.call(node) if pos == @path.size
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
              subenum = ::JsonPath.new(sub_path[2, sub_path.size - 3]).on(node[e])
              each(node[e], pos + 1, &blk) if subenum.any?{|n| true}
            end
          else
            if node.is_a?(Array)
              @obj = node
              array_args = sub_path.gsub('@','@obj').split(':')
              start_idx = process_function_or_literal(array_args[0], 0)
              next unless start_idx
              start_idx %= node.size
              end_idx = (array_args[1] && process_function_or_literal(array_args[1], -1) || (sub_path.count(':') == 0 ? start_idx : -1))
              next unless end_idx
              end_idx %= node.size
              step = process_function_or_literal(array_args[2], 1)
              next unless step
              (start_idx..end_idx).step(step) {|i| each(node[i], pos + 1, &blk)}
            end
          end
        end
      else
        blk.call(node) if pos == (@path.size - 1) && node && allow_eval? && eval("node #{@path[pos]}")
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

    private
    def process_function_or_literal(exp, default)
      if exp.nil?
        default
      elsif exp[0] == ?(
        allow_eval? ? eval(exp) : nil
      elsif exp.empty?
        default
      else
        Integer(exp)
      end
    end

    def allow_eval?
      @options.nil? || @options[:allow_eval] != false
    end
  end
end

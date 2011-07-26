class JsonPath
  class Enumerable
    include ::Enumerable
    attr_reader :allow_eval
    alias_method :allow_eval?, :allow_eval

    def initialize(path, object, options = nil)
      @path, @object, @options = path.path, object, options
      @allow_eval = @options && @options.key?(:allow_eval) ? @options[:allow_eval] : true
      @mode = @options && @options[:mode]
    end

    def each(context = @object, key = nil, pos = 0, &blk)
      node = key ? context[key] : context
      return yield_value(blk, context, key) if pos == @path.size
      case expr = @path[pos]
      when '*', '..'
        each(context, key, pos + 1, &blk)
      when '$'
        each(context, key, pos + 1, &blk) if node == @object
      when '@'
        each(context, key, pos + 1, &blk)
      when /^\[(.*)\]$/
        expr[1,expr.size - 2].split(',').each do |sub_path|
          case sub_path[0]
          when ?', ?"
            if node.is_a?(Hash)
              k = sub_path[1,sub_path.size - 2]
              each(node, k, pos + 1, &blk) if node.key?(k)
            end
          when ??
            (node.is_a?(Hash) ? node.keys : (0..node.size)).each do |e|
              subenum = ::JsonPath.new(sub_path[2, sub_path.size - 3]).on(node[e])
              each(node, e, pos + 1, &blk) if subenum.any?{|n| true}
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
              (start_idx..end_idx).step(step) {|i| each(node, i, pos + 1, &blk)}
            end
          end
        end
      else
        if pos == (@path.size - 1) && node && allow_eval?
          if eval("node #{@path[pos]}")
            yield_value(blk, context, key)
          end
        end
      end

      if pos > 0 && @path[pos-1] == '..'
        case node
        when Hash  then node.each {|k, v| each(node, k, pos, &blk) }
        when Array then node.each_with_index {|n, i| each(node, i, pos, &blk) }
        end
      end
    end

    private
    def yield_value(blk, context, key)
      @substitute_with = nil
      case @mode
      when nil
        blk.call(key ? context[key] : context)
      when :substitute
        if key
          context[key] = blk.call(context[key])
        else
          context.replace(blk.call(context[key]))
        end
      end
    end

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
  end
end

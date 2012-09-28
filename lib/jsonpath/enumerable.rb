class JsonPath
  class Enumerable
    include ::Enumerable
    attr_reader :allow_eval
    alias_method :allow_eval?, :allow_eval

    def initialize(path, object, mode, options = nil)
      @path, @object, @mode, @options = path.path, object, mode, options
      @allow_eval = @options && @options.key?(:allow_eval) ? @options[:allow_eval] : true
    end

    def each(context = @object, key = nil, pos = 0, &blk)
      node = key ? context[key] : context
      @_current_node = node
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
            raise "Cannot use ?(...) unless eval is enabled" unless allow_eval?
            case node
            when Hash, Array
              (node.is_a?(Hash) ? node.keys : (0..node.size)).each do |e|
                each(node, e, pos + 1) { |n|
                  @_current_node = n
                  yield n if process_function_or_literal(sub_path[1, sub_path.size - 1])
                }
              end
            else
              yield node if process_function_or_literal(sub_path[1, sub_path.size - 1])
            end
          else
            if node.is_a?(Array)
              array_args = sub_path.split(':')
              if array_args[0] == ?*
                start_idx = 0
                end_idx = node.size - 1
              else
                start_idx = process_function_or_literal(array_args[0], 0)
                next unless start_idx
                end_idx = (array_args[1] && process_function_or_literal(array_args[1], -1) || (sub_path.count(':') == 0 ? start_idx : -1))
                next unless end_idx
              end
              start_idx %= node.size
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
      case @mode
      when nil
        blk.call(key ? context[key] : context)
      when :compact
        context.delete(key) if key && context[key].nil?
      when :delete
        context.delete(key) if key
      when :substitute
        if key
          context[key] = blk.call(context[key])
        else
          context.replace(blk.call(context[key]))
        end
      end
    end

    def process_function_or_literal(exp, default = nil)
      if exp.nil?
        default
      elsif exp[0] == ?(
        #p @_current_node
        #p exp.gsub(/@/, '@_current_node')
        #p eval(exp.gsub(/@/, '@_current_node'))
        allow_eval? ? @_current_node && eval(exp.gsub(/@/, '@_current_node')) : nil
      elsif exp.empty?
        default
      else
        Integer(exp)
      end
    end
  end
end

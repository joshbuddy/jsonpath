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
                @_current_node = node[e]
                if process_function_or_literal(sub_path[1, sub_path.size - 1])
                  each(@_current_node, nil, pos + 1, &blk)
                end
              end
            else
              yield node if process_function_or_literal(sub_path[1, sub_path.size - 1])
            end
          else
            if node.is_a?(Array)
              next if node.empty?
              array_args = sub_path.split(':')
              if array_args[0] == ?*
                start_idx = 0
                end_idx = node.size - 1
              else
                start_idx = process_function_or_literal(array_args[0], 0)
                next unless start_idx
                end_idx = (array_args[1] && process_function_or_literal(array_args[1], -1) || (sub_path.count(':') == 0 ? start_idx : -1))
                next unless end_idx
                if start_idx == end_idx
                  next unless start_idx < node.size 
                end
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
        return nil unless allow_eval? && @_current_node
        identifiers = /@?(\.(\w+))+/.match(exp)

        if !identifiers.nil? && !@_current_node.methods.include?(identifiers[2].to_sym)
          exp_to_eval = exp.dup
          exp_to_eval[identifiers[0]] = identifiers[0].split('.').map{|el| el == '@' ? '@_current_node' : "['#{el}']"}.join
          begin
            return eval(exp_to_eval)
          rescue StandardError # if eval failed because of bad arguments or missing methods
            return default
          end
        end

        # otherwise eval as is
        # TODO: this eval is wrong, because hash accessor could be nil and nil cannot be compared with anything,
        # for instance, @_current_node['price'] - we can't be sure that 'price' are in every node, but it's only in several nodes
        # I wrapped this eval into rescue returning false when error, but this eval should be refactored.
        begin
          eval(exp.gsub(/@/, '@_current_node'))
        rescue
          false
        end
      elsif exp.empty?
        default
      else
        Integer(exp)
      end
    end
  end
end

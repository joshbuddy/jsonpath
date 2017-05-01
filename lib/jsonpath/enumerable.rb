class JsonPath
  class Enumerable
    include ::Enumerable
    attr_reader :allow_eval
    alias_method :allow_eval?, :allow_eval

    def initialize(path, object, mode, options = nil)
      @path = path.path
      @object = object
      @mode = mode
      @options = options
      @allow_eval = if @options && @options.key?(:allow_eval)
                      @options[:allow_eval]
                    else
                      true
                    end
    end

    def each(context = @object, key = nil, pos = 0, &blk)
      node = key ? context[key] : context
      @_current_node = node
      return yield_value(blk, context, key) if pos == @path.size
      case expr = @path[pos]
      when '*', '..', '@'
        each(context, key, pos + 1, &blk)
      when '$'
        each(context, key, pos + 1, &blk) if node == @object
      when /^\[(.*)\]$/
        handle_wildecard(node, expr, context, key, pos, &blk)
      else
        if pos == (@path.size - 1) && node && allow_eval?
          yield_value(blk, context, key) if instance_eval("node #{@path[pos]}")
        end
      end

      if pos > 0 && @path[pos - 1] == '..'
        case node
        when Hash  then node.each { |k, _| each(node, k, pos, &blk) }
        when Array then node.each_with_index { |_, i| each(node, i, pos, &blk) }
        end
      end
    end

    private

    def handle_wildecard(node, expr, context, key, pos, &blk)
      expr[1, expr.size - 2].split(',').each do |sub_path|
        case sub_path[0]
        when '\'', '"'
          next unless node.is_a?(Hash)
          k = sub_path[1, sub_path.size - 2]
          each(node, k, pos + 1, &blk) if node.key?(k)
        when '?'
          handle_question_mark(sub_path, node, pos, &blk)
        else
          next unless node.is_a?(Array) && !node.empty?
          array_args = sub_path.split(':')
          if array_args[0] == '*'
            start_idx = 0
            end_idx = node.size - 1
          else
            start_idx = process_function_or_literal(array_args[0], 0)
            next unless start_idx
            end_idx = (array_args[1] && process_function_or_literal(array_args[1], -1) || (sub_path.count(':') == 0 ? start_idx : -1))
            next unless end_idx
            next if start_idx == end_idx && start_idx >= node.size
          end
          start_idx %= node.size
          end_idx %= node.size
          step = process_function_or_literal(array_args[2], 1)
          next unless step
          (start_idx..end_idx).step(step) { |i| each(node, i, pos + 1, &blk) }
        end
      end
    end

    def handle_question_mark(sub_path, node, pos, &blk)
      raise 'Cannot use ?(...) unless eval is enabled' unless allow_eval?
      case node
      when Array
        node.size.times do |index|
          @_current_node = node[index]
          if process_function_or_literal(sub_path[1, sub_path.size - 1])
            each(@_current_node, nil, pos + 1, &blk)
          end
        end
      when Hash
        if process_function_or_literal(sub_path[1, sub_path.size - 1])
          each(@_current_node, nil, pos + 1, &blk)
        end
      else
        yield node if process_function_or_literal(sub_path[1, sub_path.size - 1])
      end
    end

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
      return default if exp.nil? || exp.empty?
      return Integer(exp) if exp[0] != '('
      return nil unless allow_eval? && @_current_node

      identifiers = /@?(\.(\w+))+/.match(exp)
      # puts JsonPath.on(@_current_node, "#{identifiers}") unless identifiers.nil? ||
      #                                                           @_current_node
      #                                                           .methods
      #                                                           .include?(identifiers[2].to_sym)

      unless identifiers.nil? ||
             @_current_node.methods.include?(identifiers[2].to_sym)

        exp_to_eval = exp.dup
        exp_to_eval[identifiers[0]] = identifiers[0].split('.').map do |el|
          el == '@' ? '@_current_node' : "['#{el}']"
        end.join

        begin
          return instance_eval(exp_to_eval)
          # if eval failed because of bad arguments or missing methods
        rescue StandardError
          return default
        end
      end

      # otherwise eval as is
      # TODO: this eval is wrong, because hash accessor could be nil and nil
      # cannot be compared with anything, for instance,
      # @a_current_node['price'] - we can't be sure that 'price' are in every
      # node, but it's only in several nodes I wrapped this eval into rescue
      # returning false when error, but this eval should be refactored.
      begin
        instance_eval(exp.gsub(/@/, '@_current_node'))
      rescue
        false
      end
    end
  end
end

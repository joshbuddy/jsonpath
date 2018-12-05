# frozen_string_literal: true

class JsonPath
  class Enumerable
    include ::Enumerable

    def initialize(path, object, mode, options = {})
      @path = path.path
      @object = object
      @mode = mode
      @options = options
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
      end

      if pos > 0 && @path[pos - 1] == '..' || (@path[pos - 1] == '*' && @path[pos] != '..')
        case node
        when Hash  then node.each { |k, _| each(node, k, pos, &blk) }
        when Array then node.each_with_index { |_, i| each(node, i, pos, &blk) }
        end
      end
    end

    private

    def handle_wildecard(node, expr, _context, _key, pos, &blk)
      expr[1, expr.size - 2].split(',').each do |sub_path|
        case sub_path[0]
        when '\'', '"'
          if node.is_a?(Hash)
            k = sub_path[1, sub_path.size - 2]
            node[k] ||= nil if @options[:default_path_leaf_to_null]
            each(node, k, pos + 1, &blk) if node.key?(k)
          end
        when '?'
          handle_question_mark(sub_path, node, pos, &blk)
        else
          next if node.is_a?(Array) && node.empty?
          array_args = sub_path.split(':')
          if array_args[0] == '*'
            start_idx = 0
            end_idx = node.size - 1
          elsif sub_path.count(':') == 0
            start_idx = end_idx = process_function_or_literal(array_args[0], 0)
            next unless start_idx
            next if start_idx >= node.size
          else
            start_idx = process_function_or_literal(array_args[0], 0)
            next unless start_idx
            end_idx = array_args[1] && ensure_exclusive_end_index(process_function_or_literal(array_args[1], -1)) || -1
            next unless end_idx
            next if start_idx == end_idx && start_idx >= node.size
          end
          start_idx %= node.size
          end_idx %= node.size
          step = process_function_or_literal(array_args[2], 1)
          next unless step
          if @mode == :delete
            (start_idx..end_idx).step(step) { |i| node[i] = nil }
            node.compact!
          else
            (start_idx..end_idx).step(step) { |i| each(node, i, pos + 1, &blk) }
          end
        end
      end
    end

    def ensure_exclusive_end_index(value)
      return value unless value.is_a?(Integer) && value > 0

      value - 1
    end

    def handle_question_mark(sub_path, node, pos, &blk)
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
      key = Integer(key) rescue key if key
      case @mode
      when nil
        blk.call(key ? context[key] : context)
      when :compact
        if key && context[key].nil?
          key.is_a?(Integer) ? context.delete_at(key) : context.delete(key)
        end
      when :delete
        if key
          key.is_a?(Integer) ? context.delete_at(key) : context.delete(key)
        else
          context.replace({})
        end
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
      return nil unless @_current_node

      identifiers = /@?((?<!\d)\.(?!\d)(\w+))+/.match(exp)
      if !identifiers.nil? && !@_current_node.methods.include?(identifiers[2].to_sym)
        exp_to_eval = exp.dup
        exp_to_eval[identifiers[0]] = identifiers[0].split('.').map do |el|
          el == '@' ? '@' : "['#{el}']"
        end.join
        begin
          return JsonPath::Parser.new(@_current_node).parse(exp_to_eval)
        rescue StandardError
          return default
        end
      end
      JsonPath::Parser.new(@_current_node).parse(exp)
    end
  end
end

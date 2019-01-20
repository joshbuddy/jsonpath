# frozen_string_literal: true

require 'strscan'
require 'to_regexp'

class JsonPath
  # Parser parses and evaluates an expression passed to @_current_node.
  class Parser
    def initialize(node)
      @_current_node = node
      @_expr_map = {}
    end

    def parse(exp)
      exps = exp.split(/(&&)|(\|\|)/)
      construct_expression_map(exps)
      @_expr_map.each {|k, v| exp.sub!(k, "#{v}")}
      raise ArgumentError, "unmatched parenthesis in expression: #{exp}" unless check_parenthesis_count(exp)
      while (exp.include?("("))
        exp = parse_parentheses(exp)
      end
      bool_or_exp(exp)
    end

    def construct_expression_map(exps)
      exps.each_with_index do |item, index|
        next if item == '&&' || item == '||'
        item = item.strip.gsub(/\)*$/, '').gsub(/^\(*/, '')
        @_expr_map[item] = parse_exp(item)
      end
    end

    def parse_exp(exp)
      exp = exp.sub(/@/, '').gsub(/^\(/, '').gsub(/\)$/, '').tr('"', '\'').strip
      scanner = StringScanner.new(exp)
      elements = []
      until scanner.eos?
        if scanner.scan(/\./)
          sym = scanner.scan(/\w+/)
          op = scanner.scan(/./)
          num = scanner.scan(/\d+/)
          return @_current_node.send(sym.to_sym).send(op.to_sym, num.to_i)
        end
        if t = scanner.scan(/\['[a-zA-Z@&\*\/\$%\^\?_]+'\]+/)
          elements << t.gsub(/\[|\]|'|\s+/, '')
        elsif t = scanner.scan(/(\s+)?[<>=][=~]?(\s+)?/)
          operator = t
        elsif t = scanner.scan(/(\s+)?'?.*'?(\s+)?/)
          # If we encounter a node which does not contain `'` it means
          #  that we are dealing with a boolean type.
          operand = if t == 'true'
                      true
                    elsif t == 'false'
                      false
                    else
                      operator.to_s.strip == '=~' ? t.to_regexp : t.gsub(%r{^'|'$}, '').strip
                    end
        elsif t = scanner.scan(/\/\w+\//)
        elsif t = scanner.scan(/.*/)
          raise "Could not process symbol: #{t}"
        end
      end

      el = if elements.empty?
             @_current_node
           else
             dig(elements, @_current_node)
           end
      return false if el.nil?
      return true if operator.nil? && el

      el = Float(el) rescue el
      operand = Float(operand) rescue operand

      el.__send__(operator.strip, operand)
    end

    private

    # @TODO: Remove this once JsonPath no longer supports ruby versions below 2.3
    def dig(keys, hash)
      return nil unless hash.is_a? Hash
      return nil unless hash.key?(keys.first)
      return hash.fetch(keys.first) if keys.size == 1
      prev = keys.shift
      dig(keys, hash.fetch(prev))
    end

    def parse_parentheses(str)
      opening_index = 0
      closing_index = 0

      (0..str.length-1).step(1) do |i|
        if str[i] == '('
          opening_index = i
        end
        if str[i] == ')'
          closing_index = i
          break
        end
      end

      to_parse = str[opening_index+1..closing_index-1]

      top = to_parse.split(/(&&)|(\|\|)/)
      top = top.map{|t| t.strip}
      res = bool_or_exp(top.shift)
      top.each_with_index do |item, index|
        case item
        when '&&'
          res &&= top[index + 1]
        when '||'
          res ||= top[index + 1]
        end
      end
      if closing_index+1 >= str.length && opening_index == 0
        return "#{res}"
      else
        return "#{str[0..opening_index-1]}#{res}#{str[closing_index+1..str.length]}"
      end
    end

    def bool_or_exp(b)
      if "#{b}" == 'true'
        return true
      elsif "#{b}" == 'false'
        return false
      end
      b = Float(b) rescue b
      b
    end

    def check_parenthesis_count(exp)
      return true unless exp.include?("(")
      depth = 0
      exp.chars.each do |c|
        if c == '('
          depth += 1
        elsif c == ')'
          depth -= 1
        end
      end
      depth == 0
    end
  end
end

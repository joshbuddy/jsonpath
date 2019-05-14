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

    # parse will parse an expression in the following way.
    # Split the expression up into an array of legs for && and || operators.
    # Parse this array into a map for which the keys are the parsed legs
    #  of the split. This map is then used to replace the expression with their
    # corresponding boolean or numeric value. This might look something like this:
    # ((false || false) && (false || true))
    #  Once this string is assembled... we proceed to evaluate from left to right.
    #  The above string is broken down like this:
    # (false && (false || true))
    # (false && true)
    #  false
    def parse(exp)
      exps = exp.split(/(&&)|(\|\|)/)
      construct_expression_map(exps)
      @_expr_map.each { |k, v| exp.sub!(k, v.to_s) }
      raise ArgumentError, "unmatched parenthesis in expression: #{exp}" unless check_parenthesis_count(exp)

      exp = parse_parentheses(exp) while exp.include?('(')
      bool_or_exp(exp)
    end

    # Construct a map for which the keys are the expressions
    #  and the values are the corresponding parsed results.
    # Exp.:
    # {"(@['author'] =~ /herman|lukyanenko/i)"=>0}
    # {"@['isTrue']"=>true}
    def construct_expression_map(exps)
      exps.each_with_index do |item, _index|
        next if item == '&&' || item == '||'

        item = item.strip.gsub(/\)*$/, '').gsub(/^\(*/, '')
        @_expr_map[item] = parse_exp(item)
      end
    end

    #  using a scanner break down the individual expressions and determine if
    # there is a match in the JSON for it or not.
    def parse_exp(exp)
      exp = exp.sub(/@/, '').gsub(/^\(/, '').gsub(/\)$/, '').tr('"', '\'').strip
      scanner = StringScanner.new(exp)
      elements = []
      until scanner.eos?
        if t = scanner.scan(/\['[a-zA-Z@&\*\/\$%\^\?_]+'\]|\.[a-zA-Z0-9_]+[?!]?/)
          elements << t.gsub(/[\[\]'\.]|\s+/, '')
        elsif t = scanner.scan(/(\s+)?[<>=!\-+][=~]?(\s+)?/)
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
           elsif @_current_node.is_a?(Hash)
             dig(elements, @_current_node)
           else
             elements.inject(@_current_node) do |agg, key|
               agg.__send__(key)
             end
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

    #  This will break down a parenthesis from the left to the right
    #  and replace the given expression with it's returned value.
    # It does this in order to make it easy to eliminate groups
    # one-by-one.
    def parse_parentheses(str)
      opening_index = 0
      closing_index = 0

      (0..str.length - 1).step(1) do |i|
        opening_index = i if str[i] == '('
        if str[i] == ')'
          closing_index = i
          break
        end
      end

      to_parse = str[opening_index + 1..closing_index - 1]

      #  handle cases like (true && true || false && true) in
      # one giant parenthesis.
      top = to_parse.split(/(&&)|(\|\|)/)
      top = top.map(&:strip)
      res = bool_or_exp(top.shift)
      top.each_with_index do |item, index|
        case item
        when '&&'
          res &&= top[index + 1]
        when '||'
          res ||= top[index + 1]
        end
      end

      #  if we are at the last item, the opening index will be 0
      # and the closing index will be the last index. To avoid
      # off-by-one errors we simply return the result at that point.
      if closing_index + 1 >= str.length && opening_index == 0
        return res.to_s
      else
        return "#{str[0..opening_index - 1]}#{res}#{str[closing_index + 1..str.length]}"
      end
    end

    #  This is convoluted and I should probably refactor it somehow.
    #  The map that is created will contain strings since essentially I'm
    # constructing a string like `true || true && false`.
    # With eval the need for this would disappear but never the less, here
    #  it is. The fact is that the results can be either boolean, or a number
    # in case there is only indexing happening like give me the 3rd item... or
    # it also can be nil in case of regexes or things that aren't found.
    # Hence, I have to be clever here to see what kind of variable I need to
    # provide back.
    def bool_or_exp(b)
      if b.to_s == 'true'
        return true
      elsif b.to_s == 'false'
        return false
      elsif b.to_s == ''
        return nil
      end

      b = Float(b) rescue b
      b
    end

    # this simply makes sure that we aren't getting into the whole
    #  parenthesis parsing business without knowing that every parenthesis
    # has its pair.
    def check_parenthesis_count(exp)
      return true unless exp.include?('(')

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

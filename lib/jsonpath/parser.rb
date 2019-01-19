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
      parse_with_map(exps)
      # parse_nested(exps)
      ret = parse_exp(exps.shift)
      exps.each_with_index do |item, index|
        case item
        when '&&'
          ret &&= parse_exp(exps[index + 1])
        when '||'
          ret ||= parse_exp(exps[index + 1])
        end
      end
      ret
    end

    def parse_with_map(exps)
      # Parse the expression and put their values into a map
      # with the expr as a key.
      # Once that's done, parse the whole thing and
      # use the expression map to evaluate the nested
      # conditions.
      exps.each_with_index do |item, index|
        next if item == '&&' || item == '||'
        item = item.sub(/^\(/)
        @_expr_map[item] = parse_exp(item)
      end
      p @_expr_map
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

    # (asdf(asdf))
    def parse_nested(exps)
      exps.each do |exp|
        puts exp
        # exp.chars.each{|c| puts c}
      end
    end
  end
end

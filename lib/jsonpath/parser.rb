require 'strscan'

class JsonPath
  # Parser parses and evaluates an expression passed to @_current_node.
  class Parser
    def initialize(node)
      @_current_node = node
    end

    def parse(exp)
      exps = exp.split(/(&&)|(\|\|)/)
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

    def parse_exp(exp)
      exp = exp.gsub(/@/, '').gsub(/[\(\)]/, '')
      scanner = StringScanner.new(exp)
      elements = []
      until scanner.eos?
        if scanner.scan(/\./)
          sym = scanner.scan(/\w+/)
          op = scanner.scan(/./)
          num = scanner.scan(/\d+/)
          return @_current_node.send(sym.to_sym).send(op.to_sym, num.to_i)
        end
        if t = scanner.scan(/\['\w+'\]+/)
          elements << t.gsub(/\[|\]|'|\s+/, '')
        elsif t = scanner.scan(/\s+[<>=][<>=]?\s+?/)
          operator = t
        elsif t = scanner.scan(/(\s+)?'?(\w+)?[.,]?(\w+)?'?(\s+)?/) # @TODO: At this point I should trim somewhere...
          operand = t.delete("'").strip
        elsif t = scanner.scan(/.*/)
          raise "Could not process symbol: #{t}"
        end
      end
      el = dig(elements, @_current_node)
      return false unless el
      return true if operator.nil? && el
      operand = operand.to_f if operand.to_i.to_s == operand || operand.to_f.to_s == operand
      el.send(operator.strip, operand)
    end

    private

    # @TODO: Remove this once JsonPath no longer supports ruby versions below 2.3
    def dig(keys, hash)
      return nil unless hash.key?(keys.first)
      return hash.fetch(keys.first) if keys.size == 1
      prev = keys.shift
      dig(keys, hash.fetch(prev))
    end
  end
end

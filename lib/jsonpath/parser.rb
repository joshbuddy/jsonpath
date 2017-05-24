require 'strscan'

class JsonPath
  # Parser parses and evaluates an expression passed to @_current_node.
  class Parser
    def initialize(node)
      @_current_node = node
    end

    def parse(exp)
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
        elsif t = scanner.scan(/'?(\w+)?[.,]?(\w+)?'?/)
          operand = t.delete("'").strip
        elsif t = scanner.scan(/.*/)
          raise 'Could not process symbol.'
        end
      end
      return false unless @_current_node.dig(*elements)
      return true if operator.nil? && @_current_node.dig(*elements)
      operand = operand.to_f if operand.to_i.to_s == operand || operand.to_f.to_s == operand
      @_current_node.dig(*elements).send(operator.strip, operand)
    end
  end
end

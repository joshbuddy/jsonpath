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
      until scanner.eos?
        if scanner.scan(/\./)
          sym = scanner.scan(/\w+/)
          op = scanner.scan(/./)
          num = scanner.scan(/\d+/)
          return @_current_node.send(sym.to_sym).send(op.to_sym, num.to_i)
        end
        if t = scanner.scan(/\['\w+'\]/)
          element = t
        elsif t = scanner.scan(/\s+[<>=][<>=]?\s+?/)
          operator = t
        elsif t = scanner.scan(/(\d+)?[.,]?(\d+)?/)
          operand = t
        elsif t = scanner.scan(/.*/)
          raise 'Could not process symbol.'
        end
      end
      element = element.gsub(/\[|\]|'|\s+/, '') if element
      return false unless @_current_node[element]
      return true if operator.nil? && @_current_node[element]
      case operator.strip
      when '<'
        @_current_node[element] < operand.strip.to_i
      when '>'
        @_current_node[element] > operand.strip.to_i
      when '>='
        @_current_node[element] >= operand.strip.to_i
      when '<='
        @_current_node[element] <= operand.strip.to_i
      when '=='
        @_current_node[element] == operand.strip.to_i
      end
    end
  end
end

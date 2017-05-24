require 'strscan'

class JsonPath
  # Parser parses and evaluates an expression passed to @_current_node.
  class Parser
    def initialize(node)
      @_current_node = node
    end

    def parse(exp)
      exp = exp.gsub(/@/, '').gsub(/[\(\)]/, '')
      p exp
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
          puts "t: #{t}"
          element << t
        elsif t = scanner.scan(/\s+[<>=][<>=]?\s+?/)
          operator = t
        elsif t = scanner.scan(/(\d+)?[.,]?(\d+)?/)
          operand = t
        elsif t = scanner.scan(/.*/)
          raise 'Could not process symbol.'
        end
      end
      puts "Element: #{sym}"
      element = element.gsub(/\[|\]|'|\s+/, '') if element
      return false unless @_current_node[element]
      return true if operator.nil? && @_current_node.dig(element)
      @_current_node.dig(element).send(operator.strip, operand.strip.to_i)
      # case operator.strip
      # when '<'
      #   @_current_node[element] < operand.strip.to_i
      # when '>'
      #   @_current_node[element] > operand.strip.to_i
      # when '>='
      #   @_current_node[element] >= operand.strip.to_i
      # when '<='
      #   @_current_node[element] <= operand.strip.to_i
      # when '=='
      #   @_current_node[element] == operand.strip.to_i
      # when '!='
      #   @_current_node[element] != operand.strip.to_i
      # end
    end
  end
end

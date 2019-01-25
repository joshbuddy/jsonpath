require 'ast'

class JsonPath
  class Processor < AST::Processor
    def on_begin(node)
      node.children.each { |c| process(c) }
    end

    def handler_missing(node)
      puts "missing #{node.type}"
    end
  end
end
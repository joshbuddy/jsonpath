require 'ast'

class JsonPath
  class Processor
    include AST::Processor::Mixin

    def on_begin(node)
      node.children.each { |c| process(c) }
    end

    def on_send(node)
      puts '==== SEND ===='
      node {|l, r| p l, r}
      puts '==== SEND ===='
    end

    def on_and(node)
      puts '==== AND ===='
      # node.children.each { |c| process(c) }
      left, right = *node
      puts "left: #{left}"
      puts "right: #{right}"
      puts '==== AND ===='
    end

    def on_or(node)
      puts '==== OR ===='
      p node
      puts '==== OR ===='
    end

    def handler_missing(node)
      puts "missing #{node.type}"
    end
  end
end
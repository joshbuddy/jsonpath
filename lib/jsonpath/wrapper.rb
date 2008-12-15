class JsonPath
  class Wrapper
    attr_accessor :object

    def initialize(object)
      @object = object
    end
    
    def path(expression)
      @expression = Expression.new(expression, @object)
    end
    
  end
end
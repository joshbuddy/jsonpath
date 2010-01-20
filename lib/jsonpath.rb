require File.join('jsonpath', 'expression')
require File.join('jsonpath', 'wrapper')

class JsonPath
  
  def self.path(expression)
    @expression = Expression.new(expression)
    if block_given?
      yield @expression 
    else
      @expression 
    end
  end
  
  def self.wrap(object)
    @wrapper = Wrapper.new(object)
    if block_given?
      yield @wrapper
    else
      @wrapper 
    end
  end
    
end

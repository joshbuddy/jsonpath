$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))


class JsonPath
  VERSION = '0.0.1'
  
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
require File.join('jsonpath', 'expression')
require File.join('jsonpath', 'wrapper')

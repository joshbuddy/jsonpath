# frozen_string_literal: true

class JsonPath
  module Dig

    # Similar to what Hash#dig or Array#dig
    def dig(context, *keys)
      keys.inject(context){|memo,k|
        dig_one(memo, k)
      }
    end

    # Returns a hash mapping each key from keys
    # to its dig value on context.
    def dig_as_hash(context, keys)
      keys.each_with_object({}) do |k, memo|
        memo[k] = dig_one(context, k)
      end
    end

    # Dig the value of k on context.
    def dig_one(context, k)
      case context
      when Hash
        context.dig(@options[:use_symbols] ? k.to_sym : k)
      when Array
        context.dig(k.to_i)
      else
        context.__send__(k)
      end
    end

    # Yields the block if context has a diggable
    # value for k
    def yield_if_diggable(context, k, &blk)
      if context.is_a?(Hash)
        context[k] ||= nil if @options[:default_path_leaf_to_null]
        if @options[:use_symbols]
          yield if context.key?(k.to_sym)
        else
          yield if context.key?(k)
        end
      elsif context.respond_to?(k.to_s) && !Object.respond_to?(k.to_s)
        yield
      end
    end

  end
end
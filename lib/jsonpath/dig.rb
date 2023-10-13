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
      if context.respond_to?(:to_hash)
        context.to_hash[@options[:use_symbols] ? k.to_sym : k]
      elsif context.respond_to?(:to_ary)
        context.to_ary[k.to_i]
      else
        if context.respond_to?(:dig)
          context.dig(k)
        elsif @options[:allow_send]
          context.__send__(k)
        end
      end
    end

    # Yields the block if context has a diggable
    # value for k
    def yield_if_diggable(context, k, &blk)
      if context.respond_to?(:to_ary)
        nil
      elsif context.respond_to?(:to_hash)
        k = @options[:use_symbols] ? k.to_sym : k
        return yield if context.to_hash.key?(k) || @options[:default_path_leaf_to_null]
      else
        if context.respond_to?(:dig)
          digged = dig_one(context, k)
          yield if !digged.nil? || @options[:default_path_leaf_to_null]
        elsif @options[:allow_send] && context.respond_to?(k.to_s) && !Object.respond_to?(k.to_s)
          yield
        end
      end
    end

  end
end
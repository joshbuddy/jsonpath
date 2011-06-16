class JsonPath
  class Proxy
    def initialize(obj)
      @obj = obj
    end

    def gsub(path, replacement = nil, &replacement_block)
      _gsub(deep_copy, path, replacement ? proc{replacement} : replacement_block)
    end

    def gsub!(path, replacement = nil, &replacement_block)
      _gsub(@obj, path, replacement ? proc{replacement} : replacement_block)
    end

    private
    def deep_copy
      Marshal::load(Marshal::dump(@obj))
    end

    def _gsub(obj, path, replacement)
      JsonPath.new(path, :mode => :substitute).enum_on(obj).each(&replacement)
      obj
    end
  end
end
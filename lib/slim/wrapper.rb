module Slim
  class Wrapper
    attr_reader :value, :parent

    def initialize(value, parent = nil)
      @value, @parent = value, parent
    end

    # Tries to lookup the key in this object or the parent
    # Returns nil if key is not found
    def [](name)
      return wrap(value.send(name)) if value.respond_to?(name)
      if value.respond_to?(:has_key?)
        return wrap(value[name.to_sym]) if value.has_key?(name.to_sym)
        return wrap(value[name.to_s]) if value.has_key?(name.to_s)
      end
      return wrap(value.instance_variable_get("@#{name}")) if value.instance_variable_defined?("@#{name}")
      parent[name] if parent
    end

    # Tries to call the method on this value or the parent
    # Raises exception if method is not found
    def method_missing(name, *args, &block)
      return wrap(value.send(name, *args, &block)) if value.respond_to?(name)
      if value.respond_to?(:has_key?)
        return wrap(value[name.to_sym]) if value.has_key?(name.to_sym)
        return wrap(value[name.to_s]) if value.has_key?(name.to_s)
      end
      return wrap(value.instance_variable_get("@#{name}")) if value.instance_variable_defined?("@#{name}")
      return parent.method_missing(name, *args, &block) if parent
      raise NoMethodError.new "Undefined method #{name}"
    end

    # Empty objects must appear empty for inverted sections
    def empty?
      value.respond_to?(:empty) && value.empty?
    end

    # Pass through to_s call to the wrapped object
    def to_s
      value.to_s
    end

    private

    def wrap(response)
      # Primitives are not wrapped
      if [String, Numeric, TrueClass, FalseClass, NilClass].any? {|primitive| primitive === response }
        response
        # Enumerables are mapped with wrapped values (except Hash-like objects)
      elsif !response.respond_to?(:has_key?) && response.respond_to?(:map)
        response.map {|v| wrap(v) }
      else
        Wrapper.new(response, self)
      end
    end
  end
end

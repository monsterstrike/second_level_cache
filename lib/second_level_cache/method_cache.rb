module SecondLevelCache
  class MethodCache
    def self.cache_return_value(klass, symbol, args, original_method)
      value = SecondLevelCache.cache_store.read(klass.method_cache_key(symbol, *args))
      if value.nil?
        res = if args.size > 0
                original_method.call(args)
              else
                original_method.call
              end
        SecondLevelCache.cache_store.write(klass.method_cache_key(symbol, *args), res)
      else
        value
      end
    end

    def self.cache_return_value_with_instance_method(instance, symbol, args, opt, original_method)
      key_additional = []
      if opt.key?(:with_attr)
        opt[:with_attr].each do |attr|
          key_additional << instance.send(attr)
        end
      end

      value = SecondLevelCache.cache_store.read(instance.class.method_cache_key(symbol, *key_additional))
      if value.nil?
        res = original_method.bind(instance).call
        SecondLevelCache.cache_store.write(instance.class.method_cache_key(symbol, *key_additional), res)
      else
        value
      end
    end

    module Mixin
      extend ActiveSupport::Concern

      module ClassMethods
        def method_cache(symbol, **opt)
          raise ArgumentError unless self.second_level_cache_enabled?
          begin
            original_method = method(symbol)
            if original_method.arity > 0
              args = [1]
            else
              args = []
            end
            singleton_class.send(:define_method, symbol) do |*args|
              SecondLevelCache::MethodCache.cache_return_value(self, symbol, args, original_method)
            end
          rescue NameError
            original_method = instance_method(symbol)
            define_method(symbol) do |*args|
              SecondLevelCache::MethodCache.cache_return_value_with_instance_method(self, symbol, args, opt, original_method)
            end
          end
        end

        def method_cache_key(*keys)
          "#{SecondLevelCache.cache_key_prefix}/#{self.name.downcase}/mc/#{self.cache_version}/#{keys.join('/')}"
        end
      end
    end
  end
end

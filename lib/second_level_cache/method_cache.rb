module SecondLevelCache
  class MethodCache
    def self.cache_return_value_with_class_method(klass, symbol, args, opt, original_method)
      value = SecondLevelCache.cache_store.read(klass.method_cache_key(symbol, *args))
      return value unless value.nil?

      res = if args.size > 0
              original_method.call(*args)
            else
              original_method.call
            end

      expires = if opt.key?(:expires_in)
                  opt[:expires_in]
                else
                  klass.second_level_cache_options[:expires_in]
                end
      SecondLevelCache.cache_store.write(klass.method_cache_key(symbol, *args), res, expires_in: expires)
      res
    end

    def self.cache_return_value_with_instance_method(instance, symbol, args, opt, original_method)
      key_additional = []
      if opt.key?(:with_attr)
        opt[:with_attr].each do |attr|
          key_additional << instance.send(attr)
        end
      end

      value = SecondLevelCache.cache_store.read(instance.class.method_cache_key(symbol, *key_additional))
      return value unless value.nil?

      res = if args.size > 0
              original_method.bind(instance).call(*args)
            else
              original_method.bind(instance).call
            end

      expires = if opt.key?(:expires_in)
                  opt[:expires_in]
                else
                  instance.class.second_level_cache_options[:expires_in]
                end
      SecondLevelCache.cache_store.write(instance.class.method_cache_key(symbol, *key_additional), res, expires_in: expires)
      res
    end

    module Mixin
      extend ActiveSupport::Concern

      module ClassMethods
        def method_cache(symbol, **opt)
          raise ArgumentError unless self.second_level_cache_enabled?
          begin
            original_method = method(symbol)
            singleton_class.send(:define_method, symbol) do |*args|
              SecondLevelCache::MethodCache.cache_return_value_with_class_method(self, symbol, args, opt, original_method)
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

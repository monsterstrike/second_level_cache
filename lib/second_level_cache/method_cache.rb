module SecondLevelCache
  class MethodCache
    class << self
      def cache_return_value_with_class_method(klass, symbol, args, opt, original_method)
        keys = [symbol, *args]
        cache_keys = klass.method_cache_keys(*keys, **opt)
        value = fetch_cache(cache_keys)
        return value.first if value.present? && opt.key?(:negative) && opt[:negative]
        return value if value.present?

        res = if args.size > 0
                original_method.call(*args)
              else
                original_method.call
              end
        unless opt.key?(:expires_in)
          opt[:expires_in] = klass.second_level_cache_options[:expires_in]
        end

        write_cache(cache_keys, res, opt)
        res
      end

      def cache_return_value_with_instance_method(instance, symbol, args, opt, original_method)
        key_additional = []
        if opt.key?(:with_attr)
          opt[:with_attr].each do |attr|
            key_additional << instance.send(attr)
          end
        end

        value = fetch_cache(instance.class.method_cache_keys(symbol, *key_additional, **opt))
        return value.first if value.present? && opt.key?(:negative) && opt[:negative]
        return value if value.present?

        res = if args.size > 0
                original_method.bind(instance).call(*args)
              else
                original_method.bind(instance).call
              end
        unless opt.key?(:expires_in)
          opt[:expires_in] = instance.class.second_level_cache_options[:expires]
        end

        cache_keys = instance.class.method_cache_keys(symbol, *key_additional, **opt)
        write_cache(cache_keys, res, opt)
        res
      end

      private
      def fetch_cache(keys)
        keys.shuffle.each do |key|
          v = SecondLevelCache.cache_store.read(keys.first)
          return v if v.present?
        end

        return nil
      end

      def write_cache(keys, value, opt)
        if opt.key?(:negative) && opt[:negative]
          value = [value]
        end

        keys.each do |key|
          SecondLevelCache.cache_store.write(key, value, expires_in: opt[:expires_in])
        end
      end
    end

    module Mixin
      extend ActiveSupport::Concern

      def delete_method_cache
        return unless self.class.second_level_cache_enabled?
        return unless self.class.second_level_cache_options.key?(:method_cache)

        self.class.second_level_cache_options[:method_cache].each do |target|
          key_additional = []
          if target[:opt].key?(:with_attr)
            target[:opt][:with_attr].each do |attr|
              key_additional << self.send(attr)
            end
          end

          keys = [target[:symbol], *key_additional]
          self.class.method_cache_keys(*keys, **target[:opt]).each { |key| SecondLevelCache.cache_store.delete(key) }
        end
      end
      alias update_method_cache delete_method_cache

      module ClassMethods
        def method_cache(symbol, **opt)
          raise ArgumentError unless self.second_level_cache_enabled?
          @second_level_cache_options[:method_cache] ||= []

          begin
            original_method = method(symbol)
            if original_method.arity > 0
              raise ArgumentError if !opt.key?(:composer) && !opt.key?(:with_attr)
              raise ArgumentError if opt.key?(:with_attr) && opt[:with_attr].size != original_method.arity
            end

            singleton_class.send(:define_method, symbol) do |*args|
              SecondLevelCache::MethodCache.cache_return_value_with_class_method(self, symbol, args, opt, original_method)
            end
            @second_level_cache_options[:method_cache] << {symbol: symbol, opt: opt}
          rescue NameError => e
            original_method = instance_method(symbol)
            define_method(symbol) do |*args|
              SecondLevelCache::MethodCache.cache_return_value_with_instance_method(self, symbol, args, opt, original_method)
            end
            @second_level_cache_options[:method_cache] << {symbol: symbol, opt: opt}
          end
        end

        def method_cache_keys(*keys, **opt)
          if opt.key?(:distributed) && opt.delete(:distributed)
            SecondLevelCache.number_of_distributed_keys.times.map { |i| method_cache_keys("distributed", i, keys, **opt) }.flatten
          else
            key_seed = []
            key_seed << opt[:prefix] if opt.key?(:prefix)
            key_seed << keys
            key_seed << opt[:composer].call if opt.key?(:composer)
            ["#{SecondLevelCache.cache_key_prefix}/#{self.name.downcase}/mc/#{self.cache_version}/#{key_seed.flatten.compact.join('/')}"]
          end
        end
      end
    end
  end
end

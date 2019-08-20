# -*- encoding : utf-8 -*-
module SecondLevelCache
  module ActiveRecord
    module FetchByUniqKey
      def fetch_by_uniq_keys(where_values)
        return self.where(where_values).first unless self.second_level_cache_enabled?
        raise ArgumentError if self.second_level_cache_expire_only?

        cache_key = cache_uniq_key(where_values)
        if _id = SecondLevelCache.cache_store.read(cache_key)
          self.find(_id) rescue nil
        else
          record = self.where(where_values).first
          record.tap{|record| SecondLevelCache.cache_store.write(cache_key, record.id, expires_in: self.second_level_cache_options[:expires_in])} if record
        end
      end

      def fetch_by_uniq_keys!(where_values)
        fetch_by_uniq_keys(where_values) || raise(::ActiveRecord::RecordNotFound)
      end

      def fetch_by_uniq_key(value, uniq_key_name)
        fetch_by_uniq_keys(uniq_key_name => value)
      end

      def fetch_by_uniq_key!(value, uniq_key_name)
        fetch_by_uniq_key(value, uniq_key_name) || raise(::ActiveRecord::RecordNotFound)
      end

      private

      def cache_uniq_key(where_values)
        ext_key = where_values.collect { |k,v|
          v = Digest::MD5.hexdigest(v) if v && v.size >= 32
          [k,v].join("_")
        }.join(",")
        "#{SecondLevelCache.cache_key_prefix}/#{self.name.downcase}/fbu/#{ext_key}/#{self.cache_version}"
      end
    end
  end
end

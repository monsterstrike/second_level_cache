module SecondLevelCache
  module ActiveRecord
    module FetchByIndex
      def fetch_by_index(**argv)
        return self.where(**argv).to_a unless self.second_level_cache_enabled?
        raise ArgumentError if self.second_level_cache_expire_only?
        raise ArgumentError unless self.second_level_cache_options[:cache_indexes].include?(argv.keys.sort)
        ids = SecondLevelCache.cache_store.read(cache_index_key(argv))
        unless ids
          ids = self.where(**argv).pluck(primary_key)
          SecondLevelCache.cache_store.write(cache_index_key(argv), ids, expires_in: self.second_level_cache_options[:expires_in])
        end
        return [] unless ids.present?

        from_cache = self.read_second_level_caches(*ids)
        no_exist_ids = ids - from_cache.keys

        if no_exist_ids.present?
          from_db = self.where(primary_key => no_exist_ids).to_a
          from_db.each(&:write_second_level_cache)
        else
          from_db = []
        end

        (from_cache.values + from_db).sort_by { |r| r.send(primary_key) }
      end

      def cache_index_key(kv)
        "#{SecondLevelCache.cache_key_prefix}/#{self.name.downcase}/fbi/#{kv.keys.sort.join(':')}/#{kv.values_at(*kv.keys.sort).join(':')}/#{self.cache_version}"
      end
    end
  end
end

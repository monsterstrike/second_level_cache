module SecondLevelCache
  module ActiveRecord
    module FetchByIndex
      def fetch_by_index(key, value)
        raise ArgumentError unless self.second_level_cache_enabled?
        ids = SecondLevelCache.cache_store.read(cache_index_key(key, value))
        unless ids
          ids = self.where(key => value).pluck(primary_key)
          SecondLevelCache.cache_store.write(cache_index_key(key, value), ids)
        end

        from_cache = self.read_second_level_caches(*ids)
        no_exist_ids = ids - from_cache.keys
        if no_exist_ids.size > 0
          from_db = self.where(primary_key => no_exist_ids).to_a
          from_db.each(&:write_second_level_cache)
        else
          from_db = []
        end


        (from_cache.values + from_db).sort_by { |r| r.send(primary_key) }
      end

      private

      def cache_index_key(key, value)
        "#{self.cache_key_prefix}/#{self.name.downcase}/fbi/#{key}/#{value}"
      end
    end
  end
end

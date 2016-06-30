# -*- encoding : utf-8 -*-
require "second_level_cache/serializer"

module RecordMarshal
  class << self
    def dump(record)
      SecondLevelCache::Serializer.dump(record)
    end

    # load a cached record
    def load(klass, serialized)
      return unless serialized

      if serialized.kind_of?(Array)
        record = serialized[0].constantize.allocate
        record.init_with('attributes' => serialized[1])
        record
      else
        attrs = SecondLevelCache::Serializer.load(klass, serialized)
        klass.instantiate(attrs)
      end
    end
  end
end

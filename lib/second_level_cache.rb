# -*- encoding : utf-8 -*-
require 'active_support/all'
require 'second_level_cache/config'
require 'second_level_cache/record_marshal'

module SecondLevelCache
  def self.configure
    block_given? ? yield(Config) : Config
  end

  @@enabled = true

  def self.without_cache
    old, @@enabled = @@enabled, false
    yield if block_given?
  ensure
    @@enabled = old
  end

  def self.enabled?
    @@enabled
  end

  class << self
    delegate :logger, :cache_store, :cache_key_prefix, :to => Config
  end

  module Mixin
    extend ActiveSupport::Concern

    module ClassMethods
      attr_reader :second_level_cache_options

      def acts_as_cached(options = {})
        @second_level_cache_enabled = true
        @second_level_cache_options = options
        @second_level_cache_options[:expires_in] ||= 1.week
        @second_level_cache_options[:version] ||= 0
        @second_level_cache_options[:expire_only] ||= false
      end

      def acts_as_cached_by_index(*keys)
        raise ArgumentError.new("Not enabled acts_as_cached") unless @second_level_cache_options
        if self.connection.table_exists?(self.table_name) && not_exists_index?(keys)
          raise ArgumentError.new("not using index or covering index")
        end

        @second_level_cache_options[:cache_indexes] ||= []
        @second_level_cache_options[:cache_indexes] << keys.sort
      end

      def second_level_cache_enabled?
        !!@second_level_cache_enabled && SecondLevelCache.enabled?
      end

      def second_level_cache_expire_only?
        !!@second_level_cache_options[:expire_only]
      end

      def without_second_level_cache
        old, @second_level_cache_enabled = @second_level_cache_enabled, false

        yield if block_given?
      ensure
        @second_level_cache_enabled = old
      end

      def cache_store
        Config.cache_store
      end

      def logger
        Config.logger
      end

      def cache_key_prefix
        Config.cache_key_prefix
      end

      def cache_version
        second_level_cache_options[:version]
      end

      def second_level_cache_key(id)
        "#{cache_key_prefix}/#{name.downcase}/#{id}/#{cache_version}"
      end

      def read_second_level_cache(id)
        if self.second_level_cache_enabled? && !self.second_level_cache_expire_only?
          RecordMarshal.load(self, SecondLevelCache.cache_store.read(second_level_cache_key(id)))
        end
      end

      def read_second_level_caches(*ids)
        if self.second_level_cache_enabled? && !self.second_level_cache_expire_only?
          cache_keys = Hash[ids.map { |id| second_level_cache_key(id) }.zip(ids)]
          SecondLevelCache.cache_store.read_multi(*cache_keys.keys).each_with_object(Hash.new) { |(cache_key, value), obj| obj[cache_keys[cache_key]] = RecordMarshal.load(self, value) }
        end
      end

      def expire_second_level_cache(id)
        if self.second_level_cache_enabled?
          SecondLevelCache.cache_store.delete(second_level_cache_key(id))
        end
      end

      private

      def exists_index?(keys)
        stringify_keys = keys.map(&:to_s)
        self.connection.indexes(self.table_name).map(&:columns).any? do |cols|
          next false if cols.size < keys.size
          zipped = cols.zip(stringify_keys)
          zipped.all? { |x| x[0] == x[1] || x[1].nil? }
        end
      end

      def not_exists_index?(keys)
        !exists_index?(keys)
      end
    end

    def second_level_cache_key
      self.class.second_level_cache_key(id)
    end

    def expire_second_level_cache
      if self.class.second_level_cache_enabled?
        SecondLevelCache.cache_store.delete(second_level_cache_key)
      end
    end

    def write_second_level_cache
      if self.class.second_level_cache_enabled? && !self.class.second_level_cache_expire_only?
        SecondLevelCache.cache_store.write(second_level_cache_key, RecordMarshal.dump(self), :expires_in => self.class.second_level_cache_options[:expires_in], :raw => true)
      end
    end

    alias update_second_level_cache write_second_level_cache

    def delete_slc_index_cache
      if self.class.second_level_cache_enabled? && self.class.second_level_cache_options.key?(:cache_indexes)
        self.class.second_level_cache_options[:cache_indexes].each do |keys|
          key_and_values = keys.each_with_object(Hash.new) { |key, obj| obj[key] = self.send(key) }
          SecondLevelCache.cache_store.delete(self.class.cache_index_key(**key_and_values))
        end
      end
    end

    alias update_slc_index_cache delete_slc_index_cache
  end
end

require 'second_level_cache/active_record' if defined?(ActiveRecord)

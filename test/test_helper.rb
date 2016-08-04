# -*- encoding : utf-8 -*-
require 'rubygems'
require 'bundler/setup'
require 'second_level_cache'
require 'test/unit'
require 'active_support/test_case'
require 'active_record_test_case_helper'
require 'database_cleaner'

SecondLevelCache.configure do |config|
  config.cache_store = ActiveSupport::Cache::MemoryStore.new
end

SecondLevelCache.logger.level = Logger::INFO

DatabaseCleaner[:active_record].strategy = :truncation

class ActiveSupport::TestCase
  setup do
    SecondLevelCache.cache_store.clear
    DatabaseCleaner.start
  end

  teardown do
    DatabaseCleaner.clean
  end
end

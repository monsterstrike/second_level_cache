# -*- encoding : utf-8 -*-
require 'active_record/test_helper'

class ActiveRecord::SecondLevelCacheTest < Test::Unit::TestCase
  def setup
    @user  = User.create :name => 'csdn', :email => 'test@csdn.com'
    @user2 = User.create :name => 'osdn', :email => 'osdn@example.com'
    book   = Book.create(user: @user)
    @score = Score.create(book: book)
  end

  def test_should_get_cache_key
    assert_equal "slc/user/#{@user.id}/#{User::CacheVersion}", @user.second_level_cache_key
  end

  def test_should_write_and_read_cache
    @user.write_second_level_cache
    assert_not_nil User.read_second_level_cache(@user.id)
    @user.expire_second_level_cache
    assert_nil User.read_second_level_cache(@user.id)
  end

  def test_should_read_multi
    @user.write_second_level_cache
    @user2.expire_second_level_cache
    assert_nil User.read_second_level_caches(@user.id, @user2.id)[@user2.id]

    @user2.write_second_level_cache
    users = User.read_second_level_caches(@user.id, @user2.id)
    assert_equal users[@user.id], @user
    assert_equal users[@user2.id], @user2
  end

  def test_should_not_write_when_expire_only
    @score.write_second_level_cache
    assert_nil Score.read_second_level_cache(@score.id)
  end

  def test_should_expire_when_expire_only
    Score.cache_store.write(@score.second_level_cache_key, @score)
    @score.expire_second_level_cache

    assert_nil Score.cache_store.read(@score.second_level_cache_key)
  end
end

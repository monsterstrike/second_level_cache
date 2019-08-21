# -*- encoding : utf-8 -*-
require 'test_helper'

class FetchByUinqKeyTest < ActiveSupport::TestCase
  def setup
    @user = User.create :name => 'hooopo', :email => 'hoooopo@gmail.com'
    @post = Post.create :slug => "foobar", :topic_id => 2
  end

  def test_cache_uniq_key
    assert_equal User.send(:cache_uniq_key, { :name => "hooopo" } ), "slc/user/fbu/name_hooopo/3"
    assert_equal User.send(:cache_uniq_key, { :foo => 1, :bar => 2 } ), "slc/user/fbu/foo_1,bar_2/3"
    assert_equal User.send(:cache_uniq_key, { :foo => 1, :bar => nil } ), "slc/user/fbu/foo_1,bar_/3"
    long_val = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
    assert_equal User.send(:cache_uniq_key, { :foo => 1, :bar => long_val } ), "slc/user/fbu/foo_1,bar_#{Digest::MD5.hexdigest(long_val)}/3"
  end

  def test_should_query_from_db_using_primary_key
    Post.fetch_by_uniq_keys(:topic_id => 2, :slug => "foobar")
    @post.expire_second_level_cache
    assert_sql(/SELECT\s+"posts".* FROM "posts"\s+WHERE "posts"."id" = \? LIMIT 1/) do
      Post.fetch_by_uniq_keys(:topic_id => 2, :slug => "foobar")
    end
  end

  def test_should_not_hit_db_using_fetch_by_uniq_key_twice
    post = Post.fetch_by_uniq_keys(:topic_id => 2, :slug => "foobar")
    assert_equal post, @post
    assert_no_queries do
      Post.fetch_by_uniq_keys(:topic_id => 2, :slug => "foobar")
    end
  end

  def test_should_fail_when_fetch_by_uniq_key_with_bang_method
    assert_raises(ActiveRecord::RecordNotFound) do
      Post.fetch_by_uniq_keys!(:topic_id => 2, :slug => "foobar1")
    end

    assert_raises(ActiveRecord::RecordNotFound) do
      User.fetch_by_uniq_key!("xxxxx", :name)
    end
  end

  def test_should_work_with_fetch_by_uniq_key
    user = User.fetch_by_uniq_key(@user.name, :name)
    assert_equal user, @user
  end

  def test_read_from_db_if_not_using_slc
    group = Group.fetch_by_uniq_keys(user_id: 1)
    assert_equal group, nil
  end

  def test_read_from_db_if_temp_disable_slc
    Post.fetch_by_uniq_keys(:topic_id => 2, :slug => "foobar")
    assert_sql(/SELECT\s+"posts".* FROM "posts"\s+WHERE "posts"."topic_id" = 2 AND "posts"."slug" = 'foobar' LIMIT 1/) do
      SecondLevelCache.without_cache do
        Post.fetch_by_uniq_keys(:topic_id => 2, :slug => "foobar")
      end
    end
  end
end

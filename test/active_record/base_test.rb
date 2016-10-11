# -*- encoding : utf-8 -*-
require 'active_record/test_helper'

class ActiveRecord::BaseTest < Test::Unit::TestCase
  def setup
    @user = User.create :name => 'csdn', :email => 'test@csdn.com'
    book = Book.create(title: "book title", body: "book body")
    @score = Score.create(book: book)
  end

  def test_should_update_cache_when_update_attributes
    @user.update_attributes :name => 'change'
    assert_equal @user.name, User.read_second_level_cache(@user.id).name
  end

  def test_should_update_cache_when_update_attribute
    @user.update_attribute :name, 'change'
    assert_equal @user.name, User.read_second_level_cache(@user.id).name
  end

  def test_should_expire_cache_when_destroy
    @user.destroy
    assert_nil User.read_second_level_cache(@user.id)
  end

  def test_should_expire_cache_when_update_counters
    assert_equal @user.books_count, 0
    @user.books.create
    assert_nil User.read_second_level_cache(@user.id)
    user = User.find(@user.id)
    assert_equal user.books_count, @user.books_count + 1
  end

  def test_should_not_update_cache_when_set_expire_only
    @score.update_attributes(score: 10)
    assert_nil Score.read_second_level_cache(@score.id)
  end
end

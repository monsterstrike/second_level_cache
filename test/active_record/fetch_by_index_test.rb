require 'active_record/test_helper'

class ActiveRecord::FetchByIndexTest < ActiveSupport::TestCase
  def setup
    @user = User.create :name => "alice", :email => "alice@example.com"
    @review  = Review.create :user_id => @user.id, :title => "title 1", :body => "body 1", :visible => true
    @review2 = Review.create :user_id => @user.id, :title => "title 2", :body => "body 2", :visible => true
  end

  def test_fetch_by_index
    reviews = Review.fetch_by_index(user_id: @user.id)
    assert_equal reviews.size, 2
    assert_equal reviews[0], @review
    assert_equal reviews[1], @review2
  end

  def test_fetch_by_index_without_db
    SecondLevelCache.cache_store.clear
    SecondLevelCache.cache_store.write(Review.cache_index_key(user_id: @user.id), [@review.id, @review2.id])
    @review.write_second_level_cache
    @review2.write_second_level_cache
    no_connection do
      reviews = Review.fetch_by_index(user_id: @user.id)
      assert_equal reviews.size, 2
      assert_equal reviews[0], @review
      assert_equal reviews[1], @review2
    end
  end

  def test_fetch_by_index_with_cache_disabled
    SecondLevelCache.cache_store.clear
    SecondLevelCache.cache_store.write(Review.cache_index_key(user_id: @user.id), [@review.id, @review2.id])
    @review.write_second_level_cache
    @review2.write_second_level_cache
    assert_sql(/SELECT\s+"reviews".* FROM "reviews"\s+WHERE "reviews"."user_id" = \d/) do
      reviews = SecondLevelCache.without_cache do
        Review.fetch_by_index(user_id: @user.id)
      end

      assert_equal reviews.size, 2
      assert_equal reviews[0], @review
      assert_equal reviews[1], @review2
    end
  end

  def test_should_expire_index_cache
    SecondLevelCache.cache_store.clear
    review3 = Review.create :user_id => @user.id, :title => "title 3", :body => "body 3", :visible => true
    Review.fetch_by_index(user_id: @user.id)
    review3.destroy
    assert_nil SecondLevelCache.cache_store.read(Review.cache_index_key(user_id: @user.id))
  end

  def test_fetch_by_index_without_record
    SecondLevelCache.cache_store.clear
    reviews = Review.fetch_by_index(user_id: @user.id + 1)
    assert_equal reviews.size, 0
  end

  def test_raise_error_if_not_using_index
    assert_raise(ArgumentError) do
      Review.acts_as_cached_by_index(:title)
    end

    assert_raise(ArgumentError) do
      Review.acts_as_cached_by_index(:user_id, :book_id, :title)
    end

    assert_raise(ArgumentError) do
      Review.acts_as_cached_by_index(:book_id, :user_id)
    end
  end

  def test_cache_index_key
    assert_equal Review.cache_index_key(user_id: @user.id), "slc/review/fbi/user_id/#{@user.id}/1"
    assert_equal Review.cache_index_key(user_id: @user.id, book_id: 1), "slc/review/fbi/book_id:user_id/1:#{@user.id}/1"
  end
end

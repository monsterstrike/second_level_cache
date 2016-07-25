require 'active_record/test_helper'

class ActiveRecord::FetchByIndexTest < Test::Unit::TestCase
  def setup
    @user = User.create :name => "alice", :email => "alice@example.com"
    @book  = Review.create :user_id => @user.id, :title => "title 1", :body => "body 1", :visible => true
    @book2 = Review.create :user_id => @user.id, :title => "title 2", :body => "body 2", :visible => true
  end

  def test_fetch_by_index
    reviews = Review.fetch_by_index(:user_id, @user.id)
    assert_equal reviews.size, 2
    assert_equal reviews[0], @book
    assert_equal reviews[1], @book2
  end

  def test_fetch_by_index_without_db
    SecondLevelCache.cache_store.clear
    SecondLevelCache.cache_store.write([Review.cache_key_prefix, Review.name.downcase, "fbi", "user_id", @user.id].join("/"), [@book.id, @book2.id])
    @book.write_second_level_cache
    @book2.write_second_level_cache
    no_connection do
      reviews = Review.fetch_by_index(:user_id, @user.id)
      assert_equal reviews.size, 2
      assert_equal reviews[0], @book
      assert_equal reviews[1], @book2
    end
  end
end

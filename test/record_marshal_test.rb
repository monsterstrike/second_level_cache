# -*- encoding : utf-8 -*-
require 'active_record/test_helper'

class RecordMarshalTest < Test::Unit::TestCase
  def setup
    @user = User.create :name => 'csdn', :email => 'test@csdn.com'
    @book = Book.create :title => "book 1", :body => "body 1", :user_id => @user.id
    @review = Review.create :user_id => @user.id, :book_id => @book.id, :title => "Most insane car ever!", :body => "Ferrari F12 is a most insane ever!", :visible => false
  end

  def test_should_dump_active_record_object
    dumped = RecordMarshal.dump(@review)
    assert dumped.is_a?(String)
    loaded = MessagePack.load(dumped)
    assert_equal 1, loaded[0]
    assert_equal @review.body, loaded[1]
    assert_equal @review.book_id, loaded[2]
    assert_equal %i{year month day hour min sec utc_offset}.map {|i| @review.created_at.send(i)}, loaded[3]
    assert_equal @review.id, loaded[4]
    assert_equal @review.title, loaded[5]
    assert_equal %i{year month day hour min sec utc_offset}.map {|i| @review.updated_at.send(i)}, loaded[6]
    assert_equal @review.user_id, loaded[7]
    assert_equal @review.visible, loaded[8]
  end


  def test_should_load_active_record_object
    @user.write_second_level_cache
    assert_equal @user, User.read_second_level_cache(@user.id)
  end


  def test_should_load_nil
    @user.expire_second_level_cache
    assert_nil User.read_second_level_cache(@user.id)
  end

  def test_should_load_active_record_object_without_association_cache
    @user.books
    @user.write_second_level_cache
    assert_empty User.read_second_level_cache(@user.id).association_cache
  end
end

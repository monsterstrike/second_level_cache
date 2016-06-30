# -*- encoding : utf-8 -*-
require 'active_record/test_helper'

class RecordMarshalTest < Test::Unit::TestCase
  def setup
    @user = User.create :name => 'csdn', :email => 'test@csdn.com'
    @review = Review.create :user_id => @user.id, :title => "Most insane car ever!", :body => "Ferrari F12 is a most insane ever!", :visible => false
  end

  def test_should_dump_active_record_object
    dumped = RecordMarshal.dump(@review)
    assert dumped.is_a?(String)
    loaded = MessagePack.load(dumped)
    assert_equal 1, loaded[0]
    assert_equal @review.body, loaded[1]
    assert_equal %i{year month day hour min sec utc_offset}.map {|i| @review.created_at.send(i)}, loaded[2]
    assert_equal @review.id, loaded[3]
    assert_equal @review.title, loaded[4]
    assert_equal %i{year month day hour min sec utc_offset}.map {|i| @review.updated_at.send(i)}, loaded[5]
    assert_equal @review.user_id, loaded[6]
    assert_equal @review.visible, loaded[7]
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

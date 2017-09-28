require 'active_record/test_helper'

class SecondLevelCache::MethodCacheTest < Test::Unit::TestCase
  def setup
    @user = User.create :name => "alice", :email => "alice@example.com"
    @bob = User.create :name => "bob", :email => "bob@example.com"
    @carol = User.create :name => "carol", :email => "carol@example.com"
  end

  def test_method_cache_key
    assert_equal User.method_cache_key("alice"), "slc/user/mc/3/alice"
    assert_equal User.method_cache_key("alice", *[]), "slc/user/mc/3/alice"
  end

  def test_method_cache_class_method
    User.find_alice
    no_connection do
      alice = User.find_alice
      assert_not_nil alice
      assert_equal alice.name, "alice"
    end
  end

  def test_method_cache_class_method_with_args
    User.find_by_name("alice")
    User.find_by_name("bob")
    no_connection do
      alice = User.find_by_name("alice")
      bob = User.find_by_name("bob")

      assert_not_nil alice
      assert_equal alice.name, "alice"
      assert_not_nil bob
      assert_equal bob.name, "bob"
    end
  end

  def test_method_cache_class_method_with_singleton_class
    User.find_bob
    no_connection do
      bob = User.find_bob
      assert_not_nil bob
      assert_equal bob.name, "bob"
    end
  end

  def test_method_cache_instance_method
    alice = User.find_alice
    alice.find_carol
    no_connection do
      b = alice.find_carol
      assert_not_nil b
      assert_equal b.name, "carol"
    end
  end

  def test_method_cache_instance_method_with_attr
    alice = User.find_alice
    alice.find_myself
    bob = User.find_bob
    bob.find_myself

    no_connection do
      alice_myself = alice.find_myself
      bob_myself = bob.find_myself

      assert_not_nil alice_myself
      assert_equal alice_myself.name, "alice"
      assert_not_nil bob_myself
      assert_equal bob_myself.name, "bob"
    end
  end
end

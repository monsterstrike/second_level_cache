require 'test_helper'

class SecondLevelCache::MethodCacheTest < ActiveSupport::TestCase
  def setup
    @user = User.create :name => "alice", :email => "alice@example.com"
    @bob = User.create :name => "bob", :email => "bob@example.com"
    @carol = User.create :name => "carol", :email => "carol@example.com"
    @ellen = User.create :name => "ellen", :email => "ellen@example.com"
  end

  def test_method_cache_keys
    assert_equal User.method_cache_keys("alice"), ["slc/user/mc/3/alice"]
    assert_equal User.method_cache_keys("alice", *[]), ["slc/user/mc/3/alice"]
    assert_equal User.method_cache_keys("alice", "bob"), ["slc/user/mc/3/alice/bob"]
    assert_equal User.method_cache_keys("alice", distributed: true), [
      "slc/user/mc/3/0/alice",
      "slc/user/mc/3/1/alice",
      "slc/user/mc/3/2/alice",
      "slc/user/mc/3/3/alice",
      "slc/user/mc/3/4/alice",
      "slc/user/mc/3/5/alice",
      "slc/user/mc/3/6/alice",
      "slc/user/mc/3/7/alice",
      "slc/user/mc/3/8/alice",
      "slc/user/mc/3/9/alice",
    ]
  end

  def test_method_cache_class_method
    User.find_alice
    no_connection do
      alice = User.find_alice
      assert_not_nil alice
      assert_equal alice.name, "alice"
    end
  end

  def test_method_cache_class_method_delete_when_save
    alice = User.find_alice
    alice.email = "alice@exmaple.org"
    alice.save

    assert_queries do
      User.find_alice
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

  def test_method_cache_class_method_with_args_if_delete_when_save
    alice = User.find_by_name("alice")
    alice.email = "alice@example.org"
    alice.save

    assert_queries do
      User.find_by_name("alice")
    end
  end

  def test_method_cachle_class_method_with_expires
    User.find_by_email("alice@example.com")
    no_connection do
      User.find_by_email("alice@example.com")
    end

    sleep 1.5

    assert_queries do
      User.find_by_email("alice@example.com")
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

  def test_method_cache_class_method_with_negative
    User.find_frank
    no_connection do
      frank = User.find_frank
      assert_nil frank
    end
  end

  def test_method_cache_class_method_with_negative_and_value
    User.find_negative_alice
    no_connection do
      alice = User.find_negative_alice
      assert_not_nil alice
      assert_equal alice.name, "alice"
    end
  end

  def test_method_cache_class_method_with_distributed
    User.get_all
    User.method_cache_keys("get_all", distributed: true).each do |key|
      v = SecondLevelCache.cache_store.read(key)
      assert_not_nil v
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

  def test_method_cache_instance_method_delete_when_save
    alice = User.find_alice
    alice.find_carol
    alice.email = "alice@example.org"
    alice.save

    assert_queries do
      alice.find_carol
    end
  end

  def test_method_cache_instance_method_with_negative
    alice = User.find_alice
    alice.find_eve

    no_connection do
      f = alice.find_eve
      assert_nil f
    end
  end

  def test_method_cache_instance_method_with_negative_and_value
    alice = User.find_alice
    alice.find_negative_carol

    no_connection do
      carol = alice.find_negative_carol
      assert_not_nil carol
      assert_equal carol.name, "carol"
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

  def test_method_cache_instance_method_with_expires
    alice = User.find_alice
    alice.find_ellen
    no_connection do
      alice.find_ellen
    end

    sleep 1.5

    assert_queries do
      alice.find_ellen
    end
  end

  def test_method_cache_instance_method_with_attr_and_expires
    alice = User.find_alice
    alice.find_myself_2
    no_connection do
      alice.find_myself_2
    end

    sleep 1.5

    assert_queries do
      alice.find_myself_2
    end
  end

  def test_method_cache_instance_method_delete_when_save
    obj = User.find_alice
    alice = obj.find_myself
    alice.email = "alice@example.org"
    alice.save

    got = obj.find_myself
    assert_equal got.email, "alice@example.org"
  end
end

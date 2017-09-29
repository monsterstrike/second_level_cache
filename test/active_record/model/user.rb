# -*- encoding : utf-8 -*-
ActiveRecord::Base.connection.create_table(:users, :force => true) do |t|
  t.text    :options
  t.string  :name
  t.string  :email
  t.integer :books_count, :default => 0
  t.integer :images_count, :default => 0
  t.timestamps
end

class User < ActiveRecord::Base
  CacheVersion = 3
  serialize :options, Array
  acts_as_cached(:version => CacheVersion, :expires_in => 3.day)

  has_many :books
  has_many :images, :as => :imagable

  def self.find_alice
    User.where(name: "alice").first
  end
  method_cache :find_alice

  def self.find_by_name(name)
    User.where(name: name).first
  end
  method_cache :find_by_name

  def self.find_by_email(email)
    User.where(email: email).first
  end
  method_cache :find_by_email, expires_in: 1

  def find_carol
    User.where(name: "carol").first
  end
  method_cache :find_carol

  def find_ellen
    User.where(name: "ellen").first
  end
  method_cache :find_ellen, expires_in: 1

  def find_myself
    User.where(name: self.name).first
  end
  method_cache :find_myself, with_attr: %i{name}

  def find_myself_2
    User.where(name: self.name).first
  end
  method_cache :find_myself_2, with_attr: %i{name}, expires_in: 1

  class << self
    def find_bob
      User.where(name: "bob").first
    end
    User.method_cache :find_bob
  end
end

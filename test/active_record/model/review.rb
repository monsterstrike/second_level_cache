# -*- encoding : utf-8 -*-
ActiveRecord::Base.connection.create_table(:reviews, :force => true) do |t|
  t.integer :user_id
  t.string  :title
  t.text    :body
  t.boolean :visible
  t.timestamps
end

class Review < ActiveRecord::Base
  CacheVersion = 1
  acts_as_cached(:version => CacheVersion, :expires_in => 1.day)
end

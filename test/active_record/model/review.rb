# -*- encoding : utf-8 -*-
ActiveRecord::Base.connection.create_table(:reviews, :force => true) do |t|
  t.integer :user_id
  t.integer :book_id
  t.string  :title
  t.text    :body
  t.boolean :visible
  t.date    :visible_at
  t.timestamps
end
ActiveRecord::Base.connection.add_index(:reviews, %i{user_id book_id})

class Review < ActiveRecord::Base
  CacheVersion = 1
  acts_as_cached(:version => CacheVersion, :expires_in => 1.day)
  acts_as_cached_by_index(:user_id)
end

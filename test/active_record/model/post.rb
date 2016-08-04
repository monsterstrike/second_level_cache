# -*- encoding : utf-8 -*-
ActiveRecord::Base.connection.create_table(:posts, :force => true) do |t|
  t.text  :body
  t.string :slug
  t.integer :topic_id
end
ActiveRecord::Base.connection.add_index(:posts, %i{topic_id slug}, unique: true)

class Post < ActiveRecord::Base
  acts_as_cached
  belongs_to :topic, :touch => true
end

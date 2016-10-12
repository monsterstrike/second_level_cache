# -*- encoding : utf-8 -*-
ActiveRecord::Base.connection.create_table(:scores, :force => true) do |t|
  t.integer :book_id
  t.integer :score, :default => 0
end

class Score < ActiveRecord::Base
  acts_as_cached(expire_only: true)

  belongs_to :book
end

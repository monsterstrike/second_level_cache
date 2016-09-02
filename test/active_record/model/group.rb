ActiveRecord::Base.connection.create_table(:groups, :force => true) do |t|
  t.string  :name
  t.integer :user_id
  t.timestamps
end
ActiveRecord::Base.connection.add_index(:groups, %i{user_id}, unique: true)

class Group < ActiveRecord::Base
end


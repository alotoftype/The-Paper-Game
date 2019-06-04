class CreateFriends < ActiveRecord::Migration
  def self.up
    create_table :friends do |t|
      t.integer :user_id, :null => false
      t.integer :friend_user_id, :null => false

      t.timestamps
    end

		add_index(:friends, [:user_id, :friend_user_id], :unique => true, :name => 'uk_plays_user_id_friend_user_id')
  end

  def self.down
    drop_table :friends
  end
end


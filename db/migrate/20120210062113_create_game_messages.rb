class CreateGameMessages < ActiveRecord::Migration
  def self.up
    create_table :game_messages do |t|
      t.integer :user_id, :null => false
      t.integer :game_id, :null => false
      t.integer :player_id, :null => false
      t.datetime :created_at, :null => false
      t.text :message, :null => false
    end
  end

  def self.down
    drop_table :game_messages
  end
end

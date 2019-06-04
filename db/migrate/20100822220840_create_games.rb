class CreateGames < ActiveRecord::Migration
  def self.up
    create_table :games do |t|
      t.datetime :started_at
      t.datetime :ended_at
      t.boolean :is_private, :null => false
      t.boolean :is_open_invitation, :null => false
      t.integer :round_limit, :null => false
      t.integer :player_limit, :null => false
      t.integer :player_colors_seed, :null => false
      t.integer :players_count, :null => false, :default => 0
      t.string :name, :null => false

      t.timestamps
    end
  end

  def self.down
    drop_table :games
  end
end


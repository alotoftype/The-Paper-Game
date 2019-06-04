class CreatePlayers < ActiveRecord::Migration
  def self.up
    create_table :players do |t|
      t.integer :game_id, :null => false
      t.integer :user_id, :null => false
      t.integer :position, :null => false
      t.boolean :is_ejected, :null => false, :default => false
      t.boolean :is_creator, :null => false, :default => false
      t.integer :color, :null => false

      t.timestamps
    end

		add_index(:players, [:game_id, :position], :unique => true, :name => 'uk_players_game_id_position')
		add_index(:players, [:game_id, :user_id], :unique => true, :name => 'uk_players_game_id_user_id')
  end

  def self.down
    drop_table :players
  end
end


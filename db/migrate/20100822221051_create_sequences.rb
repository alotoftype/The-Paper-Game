class CreateSequences < ActiveRecord::Migration
  def self.up
    create_table :sequences do |t|
      t.integer :game_id, :null => false
      t.integer :player_id
      t.integer :queue_position
      t.integer :position, :null => false

      t.timestamps
    end

		add_index(:sequences, [:player_id, :queue_position], :unique => true, :name => 'uk_sequences_player_id_queue_position')
  end

  def self.down
    drop_table :sequences
  end
end


class CreatePlays < ActiveRecord::Migration
  def self.up
    create_table :plays do |t|
      t.integer :player_id, :null => false
      t.integer :sequence_id, :null => false
      t.integer :picture_id
      t.text :sentence
      t.integer :position

      t.timestamps
    end

		add_index(:plays, [:sequence_id, :position], :unique => true, :name => 'uk_plays_sequence_id_position')
  end

  def self.down
    drop_table :plays
  end
end
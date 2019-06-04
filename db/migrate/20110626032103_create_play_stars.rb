class CreatePlayStars < ActiveRecord::Migration
  def self.up
    create_table :play_stars do |t|
      t.integer :user_id, :null => false
      t.integer :play_id, :null => false

      t.timestamps
    end

		add_index(:play_stars, [:user_id, :play_id], :unique => true, :name => 'uk_play_stars_user_id_play_id')
  end

  def self.down
    drop_table :play_stars
  end
end


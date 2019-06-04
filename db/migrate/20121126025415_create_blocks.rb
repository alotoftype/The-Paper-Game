class CreateBlocks < ActiveRecord::Migration
  def self.up
    create_table :blocks do |t|
      t.integer :user_id, :null => false
      t.integer :blocked_user_id, :null => false

      t.timestamps
    end

		add_index(:blocks, [:user_id, :blocked_user_id], :unique => true, :name => 'uk_plays_user_id_blocked_user_id')
  end

  def self.down
    drop_table :blocks
  end
end


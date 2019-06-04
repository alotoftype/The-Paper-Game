class CreatePictures < ActiveRecord::Migration
  def self.up
    create_table :pictures do |t|
      t.string :image_file_name, :null => false
      t.string :image_content_type, :null => false
      t.string :image_file_size, :null => false
      t.integer :original_width, :null => false
      t.integer :original_height, :null => false
      t.integer :display_width, :null => false
      t.integer :display_height, :null => false

      t.timestamps
    end
  end

  def self.down
    drop_table :pictures
  end
end


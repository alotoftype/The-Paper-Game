class AddPictureUuids < ActiveRecord::Migration
  def up
    add_column :pictures, :uuid, :string, :length => 36
  end

  def down
    remove_column :pictures, :uuid
  end
end

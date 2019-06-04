class AddLastBledAtToUsers < ActiveRecord::Migration
  def change
    add_column :users, :last_bled_at, :datetime
  end
end
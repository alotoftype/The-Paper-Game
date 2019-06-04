class DailyDigest < ActiveRecord::Migration
  def up
    add_column :users, :wants_daily_digest, :boolean, :null => false, default: true
    add_column :users, :daily_digest_last_sent, :datetime
  end

  def down
    remove_column :users, :wants_daily_digest
    remove_column :users, :daily_digest_last_sent
  end
end

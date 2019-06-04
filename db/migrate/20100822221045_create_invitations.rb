class CreateInvitations < ActiveRecord::Migration
  def self.up
    create_table :invitations do |t|
      t.integer :game_id, :null => false
      t.integer :invitee_user_id, :null => false
      t.integer :inviter_user_id, :null => false
      t.boolean :has_accepted

      t.timestamps
    end

		add_index(:invitations, [:game_id, :invitee_user_id], :unique => true, :name => 'uk_invitations_game_id_invitee_user_id]')
  end

  def self.down
    drop_table :invitations
  end
end


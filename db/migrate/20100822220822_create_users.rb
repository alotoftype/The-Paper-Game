class CreateUsers < ActiveRecord::Migration
	def self.up
		create_table :users do |t|
			t.string :email, :null => false
			t.string :login, :null => false
			t.string :crypted_password
			t.string :password_salt
      t.boolean :active, :default => true, :null => false
      t.boolean :confirmed, :default => false, :null => false
			t.string :persistence_token, :null => false
			t.string :single_access_token, :null => false
			t.string :perishable_token, :null => false
			t.integer :login_count, :null => false, :default => 0
			t.integer :failed_login_count, :null => false, :default => 0
			t.datetime :last_request_at
			t.datetime :current_login_at
			t.datetime :last_login_at
			t.string :current_login_ip
			t.string :last_login_ip

			t.timestamps
		end

		add_index(:users, :login, :unique => true, :name => 'uk_users_username')
		add_index(:users, :email, :unique => true, :name => 'uk_users_email')
	end

	def self.down
		drop_table :users
	end
end


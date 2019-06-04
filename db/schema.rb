# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20140218211459) do

  create_table "authentications", :force => true do |t|
    t.integer  "user_id"
    t.string   "provider"
    t.string   "uid"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "blocks", :force => true do |t|
    t.integer  "user_id",         :null => false
    t.integer  "blocked_user_id", :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "blocks", ["user_id", "blocked_user_id"], :name => "uk_plays_user_id_blocked_user_id", :unique => true

  create_table "delayed_jobs", :force => true do |t|
    t.integer  "priority",   :default => 0
    t.integer  "attempts",   :default => 0
    t.text     "handler"
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.string   "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "delayed_jobs", ["priority", "run_at"], :name => "delayed_jobs_priority"

  create_table "friends", :force => true do |t|
    t.integer  "user_id",        :null => false
    t.integer  "friend_user_id", :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "friends", ["user_id", "friend_user_id"], :name => "uk_plays_user_id_friend_user_id", :unique => true

  create_table "game_messages", :force => true do |t|
    t.integer  "user_id",    :null => false
    t.integer  "game_id",    :null => false
    t.integer  "player_id",  :null => false
    t.datetime "created_at", :null => false
    t.text     "message",    :null => false
  end

  create_table "games", :force => true do |t|
    t.date     "started_at"
    t.date     "ended_at"
    t.boolean  "is_private",                        :null => false
    t.boolean  "is_open_invitation",                :null => false
    t.integer  "round_limit",                       :null => false
    t.integer  "player_limit",                      :null => false
    t.integer  "player_colors_seed",                :null => false
    t.integer  "players_count",      :default => 0, :null => false
    t.string   "name",                              :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "invitations", :force => true do |t|
    t.integer  "game_id",         :null => false
    t.integer  "invitee_user_id", :null => false
    t.integer  "inviter_user_id", :null => false
    t.boolean  "has_accepted"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "invitations", ["game_id", "invitee_user_id"], :name => "uk_invitations_game_id_invitee_user_id]", :unique => true

  create_table "pictures", :force => true do |t|
    t.string   "image_file_name",    :null => false
    t.string   "image_content_type", :null => false
    t.string   "image_file_size",    :null => false
    t.integer  "original_width",     :null => false
    t.integer  "original_height",    :null => false
    t.integer  "display_width",      :null => false
    t.integer  "display_height",     :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "uuid"
  end

  create_table "play_stars", :force => true do |t|
    t.integer  "user_id",    :null => false
    t.integer  "play_id",    :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "play_stars", ["user_id", "play_id"], :name => "uk_play_stars_user_id_play_id", :unique => true

  create_table "players", :force => true do |t|
    t.integer  "game_id",                       :null => false
    t.integer  "user_id",                       :null => false
    t.integer  "position",                      :null => false
    t.boolean  "is_ejected", :default => false, :null => false
    t.boolean  "is_creator", :default => false, :null => false
    t.integer  "color",                         :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "players", ["game_id", "position"], :name => "uk_players_game_id_position", :unique => true
  add_index "players", ["game_id", "user_id"], :name => "uk_players_game_id_user_id", :unique => true

  create_table "plays", :force => true do |t|
    t.integer  "player_id",   :null => false
    t.integer  "sequence_id", :null => false
    t.integer  "picture_id"
    t.text     "sentence"
    t.integer  "position"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "plays", ["sequence_id", "position"], :name => "uk_plays_sequence_id_position", :unique => true

  create_table "sequences", :force => true do |t|
    t.integer  "game_id",        :null => false
    t.integer  "player_id"
    t.integer  "queue_position"
    t.integer  "position",       :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sequences", ["player_id", "queue_position"], :name => "uk_sequences_player_id_queue_position", :unique => true

  create_table "sessions", :force => true do |t|
    t.string   "session_id", :null => false
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

  create_table "user_sessions", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", :force => true do |t|
    t.string   "email",                                     :null => false
    t.string   "login",                                     :null => false
    t.string   "crypted_password"
    t.string   "password_salt"
    t.boolean  "active",                 :default => true,  :null => false
    t.boolean  "confirmed",              :default => false, :null => false
    t.string   "persistence_token",                         :null => false
    t.string   "single_access_token",                       :null => false
    t.string   "perishable_token",                          :null => false
    t.integer  "login_count",            :default => 0,     :null => false
    t.integer  "failed_login_count",     :default => 0,     :null => false
    t.datetime "last_request_at"
    t.datetime "current_login_at"
    t.datetime "last_login_at"
    t.string   "current_login_ip"
    t.string   "last_login_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "wants_daily_digest",     :default => true,  :null => false
    t.datetime "daily_digest_last_sent"
    t.datetime "last_bled_at"
  end

  add_index "users", ["email"], :name => "uk_users_email", :unique => true
  add_index "users", ["login"], :name => "uk_users_username", :unique => true

end

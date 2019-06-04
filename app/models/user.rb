class User < ActiveRecord::Base
  has_many :players
  has_many :received_invitations, :class_name => 'Invitation', :foreign_key => 'invitee_user_id'
  has_many :sent_invitations, :class_name => 'Invitation', :foreign_key => 'inviter_user_id'
  has_many :games, :through => :players
  has_many :friends
  has_many :friend_of_users, :class_name => 'Friend', :foreign_key => 'friend_user_id'
  has_many :starred_plays, :class_name => 'PlayStar', :foreign_key => 'user_id'
  has_many :authentications, :autosave => true
  validates_confirmation_of :email
  validates_format_of :email, :with => Authlogic::Regex.email

  attr_accessible :login, :email, :email_confirmation, :password, :password_confirmation, :wants_daily_digest

  acts_as_authentic do |c|
    c.merge_validates_confirmation_of_password_field_options({:unless => :using_oauth?})
    c.merge_validates_length_of_password_field_options({:unless => :using_oauth?})
    c.merge_validates_length_of_password_confirmation_field_options({:unless => :using_oauth?})
  end

  def using_oauth?
    self.authentications.any?
  end

  # Accessible Collections

  def self.can_show(user)
    return where(:id => user.id) if (user)
    return where("0 = 1")
  end

  def self.can_index(user)
    can_show(user)
  end

  def self.can_update(user)
    return where(:id => user.id) if (user)
    return where("0 = 1")
  end

  def self.can_edit(user)
    can_update(user)
  end

  def self.can_destroy(user)
    return where(:id => user.id) if (user)
    return where("0 = 1")
  end

  def self.can_delete(user)
    can_delete(user)
  end

  def self.can_friend(user)
    return where('0 = 1') if (user == nil)
    where('NOT EXISTS (SELECT NULL FROM friends WHERE friends.friend_user_id = users.id AND friends.user_id = %{user_id})' % {:user_id => user.id})
  end

  def self.can_unfriend(user)
    return where('0 = 1') if (user == nil)
    where('EXISTS (SELECT NULL FROM friends WHERE friends.friend_user_id = users.id AND friends.user_id = %{user_id})' % {:user_id => user.id})
  end

  def self.can_block(user)
    return where('0 = 1') if (user == nil)
    where('NOT EXISTS (SELECT NULL FROM blocks WHERE blocks.blocked_user_id = users.id AND blocks.user_id = %{user_id})' % {:user_id => user.id})
  end

  def self.can_unblock(user)
    return where('0 = 1') if (user == nil)
    where('EXISTS (SELECT NULL FROM blocks WHERE blocks.blocked_user_id = users.id AND blocks.user_id = %{user_id})' % {:user_id => user.id})
  end

  # Collection Access

  def self.can_index?(user)
    if user then true else false end
  end

  def self.can_games?(user)
    if user then true else false end
  end

  def self.can_create?(user)
    if user then false else true end
  end

  def self.can_new?(user)
    User.can_create?(user)
  end

  def self.can_friend?(user)
    if user then true else false end
  end

  def self.can_unfriend?(user)
    User.can_unfriend?(user)
  end

  def self.can_block?(user)
    if user then true else false end
  end

  def self.can_unblock?(user)
    User.can_unfriend?(user)
  end

  # Member Access

  def can_show?(user)
    User.can_show(user).exists?(self)
  end

  def can_update?(user)
    User.can_show(user).exists?(self)
  end

  def can_edit?(user)
    User.can_show(user).exists?(self)
  end

  def can_friend?(user)
    User.can_friend(user).exists?(self)
  end

  def can_unfriend?(user)
    User.can_unfriend(user).exists?(self)
  end

  def can_block?(user)
    User.can_block(user).exists?(self)
  end

  def can_unblock?(user)
    User.can_unblock(user).exists?(self)
  end

  # Helper Sets

  def invitable_friends(game_id)
    self.friends.
      where{-exists(Game.
        where{ games.id == game_id }.
        joins{ players }.
        where { players.user_id == friends.friend_user_id })
      }.
      where{-exists(Game.
        where{ games.id == game_id }.
        joins{ invitations }.
        where { invitations.invitee_user_id == friends.friend_user_id })
      }.
      includes { friend }
  end

  def self.notifications
    Sequence.
      joins{ player.user }.
      joins{ game }.
      joins{ 'LEFT JOIN plays ON plays.sequence_id = sequences.id' }.
      where{ users.wants_daily_digest == true }.
      where{ (users.daily_digest_last_sent == nil) | (users.daily_digest_last_sent < 23.5.hours.ago) }.
      where{ -(game.name =~ 'test') }.
      select("CASE WHEN COALESCE(MAX(plays.position), 0) % 2 = 1 THEN 't' ELSE 'f' END AS is_picture, users.email, users.login, players.user_id, sequences.id, sequences.game_id, sequences.queue_position, games.name").
      group('users.email, users.login, players.user_id, sequences.id, sequences.game_id, sequences.queue_position, games.name').
      order('users.email, games.name, sequences.queue_position').
      inject(Hash.new) { |result, s|
        user = result[s.user_id] ||= { "email" => s.email, "login" => s.login, "games" => Hash.new }
        game = user["games"][s.game_id] ||= { "name" => s.name, "plays" => Array.new, "count" => 0 }
        game["plays"].push(s.is_picture == 't' ? true : false)
        game["count"] += 1
        result
      }
  end

  # Helper Properties

  def star_count
    self.players.joins(:plays).joins(:plays => :stars).count
  end

  def active_game_count
    Game.
      where('EXISTS (SELECT NULL FROM players JOIN sequences ON players.game_id = games.id AND sequences.player_id = players.id WHERE players.user_id = %{user_id})
        OR games.started_at IS NULL AND EXISTS (SELECT NULL FROM invitations WHERE invitations.game_id = games.id AND invitations.invitee_user_id = %{user_id} AND invitations.has_accepted IS NULL)' % {:user_id => self.id}).
      count
  end

  # Helper Methods

  def save_omniauth(omniauth)
    self.authentications.build(:provider => omniauth['provider'], :uid => omniauth['uid'])
    self.email ||= omniauth['info']['email']
    self.login ||= omniauth['info']['name']
    self.confirmed = true
    self.reset_persistence_token
    self.reset_single_access_token
    self.reset_perishable_token
    self.crypted_password = ''
    self.password_salt = ''
    self.save
  end

  def confirm
    self.confirmed = true
  end

  def activate
    self.active = true
  end

  def deactivate
    self.active = false
  end
end